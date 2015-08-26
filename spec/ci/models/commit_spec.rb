# == Schema Information
#
# Table name: commits
#
#  id           :integer          not null, primary key
#  project_id   :integer
#  ref          :string(255)
#  sha          :string(255)
#  before_sha   :string(255)
#  push_data    :text
#  created_at   :datetime
#  updated_at   :datetime
#  tag          :boolean          default(FALSE)
#  yaml_errors  :text
#  committed_at :datetime
#

require 'spec_helper'

describe Commit do
  let(:project) { FactoryGirl.create :project }
  let(:commit) { FactoryGirl.create :commit, project: project }
  let(:commit_with_project) { FactoryGirl.create :commit, project: project }
  let(:config_processor) { GitlabCiYamlProcessor.new(gitlab_ci_yaml) }

  it { should belong_to(:project) }
  it { should have_many(:builds) }
  it { should validate_presence_of :before_sha }
  it { should validate_presence_of :sha }
  it { should validate_presence_of :ref }
  it { should validate_presence_of :push_data }

  it { should respond_to :git_author_name }
  it { should respond_to :git_author_email }
  it { should respond_to :short_sha }

  describe :last_build do
    subject { commit.last_build }
    before do
      @first = FactoryGirl.create :build, commit: commit, created_at: Date.yesterday
      @second = FactoryGirl.create :build, commit: commit
    end

    it { should be_a(Build) }
    it('returns with the most recently created build') { should eq(@second) }
  end

  describe :retry do
    before do
      @first = FactoryGirl.create :build, commit: commit, created_at: Date.yesterday
      @second = FactoryGirl.create :build, commit: commit
    end

    it "creates new build" do
      expect(commit.builds.count(:all)).to eq 2
      commit.retry
      expect(commit.builds.count(:all)).to eq 3
    end
  end

  describe :project_recipients do

    context 'always sending notification' do
      it 'should return commit_pusher_email as only recipient when no additional recipients are given' do
        project = FactoryGirl.create :project,
          email_add_pusher: true,
          email_recipients: ''
        commit =  FactoryGirl.create :commit, project: project
        expected = 'commit_pusher_email'
        commit.stub(:push_data) { { user_email: expected } }
        commit.project_recipients.should == [expected]
      end

      it 'should return commit_pusher_email and additional recipients' do
        project = FactoryGirl.create :project,
          email_add_pusher: true,
          email_recipients: 'rec1 rec2'
        commit = FactoryGirl.create :commit, project: project
        expected = 'commit_pusher_email'
        commit.stub(:push_data) { { user_email: expected } }
        commit.project_recipients.should == ['rec1', 'rec2', expected]
      end

      it 'should return recipients' do
        project = FactoryGirl.create :project,
          email_add_pusher: false,
          email_recipients: 'rec1 rec2'
        commit = FactoryGirl.create :commit, project: project
        commit.project_recipients.should == ['rec1', 'rec2']
      end

      it 'should return unique recipients only' do
        project = FactoryGirl.create :project,
          email_add_pusher: true,
          email_recipients: 'rec1 rec1 rec2'
        commit = FactoryGirl.create :commit, project: project
        expected = 'rec2'
        commit.stub(:push_data) { { user_email: expected } }
        commit.project_recipients.should == ['rec1', 'rec2']
      end
    end
  end

  describe :valid_commit_sha do
    context 'commit.sha can not start with 00000000' do
      before do
        commit.sha = '0' * 40
        commit.valid_commit_sha
      end

      it('commit errors should not be empty') { commit.errors.should_not be_empty }
    end
  end

  describe :compare? do
    subject { commit_with_project.compare? }

    context 'if commit.before_sha are not nil' do
      it { should be_true }
    end
  end

  describe :short_sha do
    subject { commit.short_before_sha }

    it { should have(8).items }
    it { commit.before_sha.should start_with(subject) }
  end

  describe :short_sha do
    subject { commit.short_sha }

    it { should have(8).items }
    it { commit.sha.should start_with(subject) }
  end

  describe :create_next_builds do
    before do
      commit.stub(:config_processor).and_return(config_processor)
    end

    it "creates builds for next type" do
      commit.create_builds.should be_true
      commit.builds.reload
      commit.builds.size.should == 2

      commit.create_next_builds(nil).should be_true
      commit.builds.reload
      commit.builds.size.should == 4

      commit.create_next_builds(nil).should be_true
      commit.builds.reload
      commit.builds.size.should == 5

      commit.create_next_builds(nil).should be_false
    end
  end

  describe :create_builds do
    before do
      commit.stub(:config_processor).and_return(config_processor)
    end

    it 'creates builds' do
      commit.create_builds.should be_true
      commit.builds.reload
      commit.builds.size.should == 2
    end

    context 'for build triggers' do
      let(:trigger) { FactoryGirl.create :trigger, project: project }
      let(:trigger_request) { FactoryGirl.create :trigger_request, commit: commit, trigger: trigger }

      it 'creates builds' do
        commit.create_builds(trigger_request).should be_true
        commit.builds.reload
        commit.builds.size.should == 2
      end

      it 'rebuilds commit' do
        commit.create_builds.should be_true
        commit.builds.reload
        commit.builds.size.should == 2

        commit.create_builds(trigger_request).should be_true
        commit.builds.reload
        commit.builds.size.should == 4
      end

      it 'creates next builds' do
        commit.create_builds(trigger_request).should be_true
        commit.builds.reload
        commit.builds.size.should == 2

        commit.create_next_builds(trigger_request).should be_true
        commit.builds.reload
        commit.builds.size.should == 4
      end

      context 'for [ci skip]' do
        before do
          commit.push_data[:commits][0][:message] = 'skip this commit [ci skip]'
          commit.save
        end

        it 'rebuilds commit' do
          commit.status.should == 'skipped'
          commit.create_builds(trigger_request).should be_true
          commit.builds.reload
          commit.builds.size.should == 2
          commit.status.should == 'pending'
        end
      end
    end
  end

  describe "#finished_at" do
    let(:project) { FactoryGirl.create :project }
    let(:commit) { FactoryGirl.create :commit, project: project }

    it "returns finished_at of latest build" do
      build = FactoryGirl.create :build, commit: commit, finished_at: Time.now - 60
      build1 = FactoryGirl.create :build, commit: commit, finished_at: Time.now - 120

      commit.finished_at.to_i.should == build.finished_at.to_i
    end

    it "returns nil if there is no finished build" do
      build = FactoryGirl.create :not_started_build, commit: commit

      commit.finished_at.should be_nil
    end
  end

  describe "coverage" do
    let(:project) { FactoryGirl.create :project, coverage_regex: "/.*/" }
    let(:commit) { FactoryGirl.create :commit, project: project }

    it "calculates average when there are two builds with coverage" do
      FactoryGirl.create :build, name: "rspec", coverage: 30, commit: commit
      FactoryGirl.create :build, name: "rubocop", coverage: 40, commit: commit
      commit.coverage.should == "35.00"
    end

    it "calculates average when there are two builds with coverage and one with nil" do
      FactoryGirl.create :build, name: "rspec", coverage: 30, commit: commit
      FactoryGirl.create :build, name: "rubocop", coverage: 40, commit: commit
      FactoryGirl.create :build, commit: commit
      commit.coverage.should == "35.00"
    end

    it "calculates average when there are two builds with coverage and one is retried" do
      FactoryGirl.create :build, name: "rspec", coverage: 30, commit: commit
      FactoryGirl.create :build, name: "rubocop", coverage: 30, commit: commit
      FactoryGirl.create :build, name: "rubocop", coverage: 40, commit: commit
      commit.coverage.should == "35.00"
    end

    it "calculates average when there is one build without coverage" do
      FactoryGirl.create :build, commit: commit
      commit.coverage.should be_nil
    end
  end
end
