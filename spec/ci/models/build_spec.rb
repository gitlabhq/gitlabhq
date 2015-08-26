# == Schema Information
#
# Table name: builds
#
#  id                 :integer          not null, primary key
#  project_id         :integer
#  status             :string(255)
#  finished_at        :datetime
#  trace              :text
#  created_at         :datetime
#  updated_at         :datetime
#  started_at         :datetime
#  runner_id          :integer
#  commit_id          :integer
#  coverage           :float
#  commands           :text
#  job_id             :integer
#  name               :string(255)
#  deploy             :boolean          default(FALSE)
#  options            :text
#  allow_failure      :boolean          default(FALSE), not null
#  stage              :string(255)
#  trigger_request_id :integer
#

require 'spec_helper'

describe Build do
  let(:project) { FactoryGirl.create :project }
  let(:commit) { FactoryGirl.create :commit, project: project }
  let(:build) { FactoryGirl.create :build, commit: commit }

  it { should belong_to(:commit) }
  it { should validate_presence_of :status }

  it { should respond_to :success? }
  it { should respond_to :failed? }
  it { should respond_to :running? }
  it { should respond_to :pending? }
  it { should respond_to :trace_html }

  describe :first_pending do
    let(:first) { FactoryGirl.create :build, commit: commit, status: 'pending', created_at: Date.yesterday }
    let(:second) { FactoryGirl.create :build, commit: commit, status: 'pending' }
    before { first; second }
    subject { Build.first_pending }

    it { should be_a(Build) }
    it('returns with the first pending build') { should eq(first) }
  end

  describe :create_from do
    before do
      build.status = 'success'
      build.save
    end
    let(:create_from_build) { Build.create_from build }

    it ('there should be a pending task') do
      expect(Build.pending.count(:all)).to eq 0
      create_from_build
      expect(Build.pending.count(:all)).to be > 0
    end
  end

  describe :started? do
    subject { build.started? }

    context 'without started_at' do
      before { build.started_at = nil }

      it { should be_false }
    end

    %w(running success failed).each do |status|
      context "if build status is #{status}" do
        before { build.status = status }

        it { should be_true }
      end
    end

    %w(pending canceled).each do |status|
      context "if build status is #{status}" do
        before { build.status = status }

        it { should be_false }
      end
    end
  end

  describe :active? do
    subject { build.active? }

    %w(pending running).each do |state|
      context "if build.status is #{state}" do
        before { build.status = state }

        it { should be_true }
      end
    end

    %w(success failed canceled).each do |state|
      context "if build.status is #{state}" do
        before { build.status = state }

        it { should be_false }
      end
    end
  end

  describe :complete? do
    subject { build.complete? }

    %w(success failed canceled).each do |state|
      context "if build.status is #{state}" do
        before { build.status = state }

        it { should be_true }
      end
    end

    %w(pending running).each do |state|
      context "if build.status is #{state}" do
        before { build.status = state }

        it { should be_false }
      end
    end
  end

  describe :ignored? do
    subject { build.ignored? }

    context 'if build is not allowed to fail' do
      before { build.allow_failure = false }

      context 'and build.status is success' do
        before { build.status = 'success' }

        it { should be_false }
      end

      context 'and build.status is failed' do
        before { build.status = 'failed' }

        it { should be_false }
      end
    end

    context 'if build is allowed to fail' do
      before { build.allow_failure = true }

      context 'and build.status is success' do
        before { build.status = 'success' }

        it { should be_false }
      end

      context 'and build.status is failed' do
        before { build.status = 'failed' }

        it { should be_true }
      end
    end
  end

  describe :trace do
    subject { build.trace_html }

    it { should be_empty }

    context 'if build.trace contains text' do
      let(:text) { 'example output' }
      before { build.trace = text }

      it { should include(text) }
      it { should have_at_least(text.length).items }
    end
  end

  describe :timeout do
    subject { build.timeout }

    it { should eq(commit.project.timeout) }
  end

  describe :duration do
    subject { build.duration }

    it { should eq(120.0) }

    context 'if the building process has not started yet' do
      before do
        build.started_at = nil
        build.finished_at = nil
      end

      it { should be_nil }
    end

    context 'if the building process has started' do
      before do
        build.started_at = Time.now - 1.minute
        build.finished_at = nil
      end

      it { should be_a(Float) }
      it { should > 0.0 }
    end
  end

  describe :options do
    let(:options) {
      {
        :image => "ruby:2.1",
        :services => [
          "postgres"
        ]
      }
    }

    subject { build.options }
    it { should eq(options) }
  end

  describe :ref do
    subject { build.ref }

    it { should eq(commit.ref) }
  end

  describe :sha do
    subject { build.sha }

    it { should eq(commit.sha) }
  end

  describe :short_sha do
    subject { build.short_sha }

    it { should eq(commit.short_sha) }
  end

  describe :before_sha do
    subject { build.before_sha }

    it { should eq(commit.before_sha) }
  end

  describe :allow_git_fetch do
    subject { build.allow_git_fetch }

    it { should eq(project.allow_git_fetch) }
  end

  describe :project do
    subject { build.project }

    it { should eq(commit.project) }
  end

  describe :project_id do
    subject { build.project_id }

    it { should eq(commit.project_id) }
  end

  describe :project_name do
    subject { build.project_name }

    it { should eq(project.name) }
  end

  describe :repo_url do
    subject { build.repo_url }

    it { should eq(project.repo_url_with_auth) }
  end

  describe :extract_coverage do
    context 'valid content & regex' do
      subject { build.extract_coverage('Coverage 1033 / 1051 LOC (98.29%) covered', '\(\d+.\d+\%\) covered') }

      it { should eq(98.29) }
    end

    context 'valid content & bad regex' do
      subject { build.extract_coverage('Coverage 1033 / 1051 LOC (98.29%) covered', 'very covered') }

      it { should be_nil }
    end

    context 'no coverage content & regex' do
      subject { build.extract_coverage('No coverage for today :sad:', '\(\d+.\d+\%\) covered') }

      it { should be_nil }
    end

    context 'multiple results in content & regex' do
      subject { build.extract_coverage(' (98.39%) covered. (98.29%) covered', '\(\d+.\d+\%\) covered') }

      it { should eq(98.29) }
    end
  end

  describe :variables do
    context 'returns variables' do
      subject { build.variables }

      let(:variables) {
        [
          {key: :DB_NAME, value: 'postgres', public: true}
        ]
      }

      it { should eq(variables) }

      context 'and secure variables' do
        let(:secure_variables) {
          [
            {key: 'SECRET_KEY', value: 'secret_value', public: false}
          ]
        }

        before do
          build.project.variables << Variable.new(key: 'SECRET_KEY', value: 'secret_value')
        end

        it { should eq(variables + secure_variables) }

        context 'and trigger variables' do
          let(:trigger) { FactoryGirl.create :trigger, project: project }
          let(:trigger_request) { FactoryGirl.create :trigger_request_with_variables, commit: commit, trigger: trigger }
          let(:trigger_variables) {
            [
              {key: :TRIGGER_KEY, value: 'TRIGGER_VALUE', public: false}
            ]
          }

          before do
            build.trigger_request = trigger_request
          end

          it { should eq(variables + secure_variables + trigger_variables) }
        end
      end
    end
  end
end
