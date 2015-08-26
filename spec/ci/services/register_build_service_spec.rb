require 'spec_helper'

describe RegisterBuildService do
  let!(:service) { RegisterBuildService.new }
  let!(:project) { FactoryGirl.create :project }
  let!(:commit) { FactoryGirl.create :commit, project: project }
  let!(:pending_build) { FactoryGirl.create :build, project: project, commit: commit }
  let!(:shared_runner) { FactoryGirl.create(:runner, is_shared: true) }
  let!(:specific_runner) { FactoryGirl.create(:runner, is_shared: false) }

  before do
    specific_runner.assign_to(project)
  end

  describe :execute do
    context 'runner follow tag list' do
      it "picks build with the same tag" do
        pending_build.tag_list = ["linux"]
        pending_build.save
        specific_runner.tag_list = ["linux"]
        service.execute(specific_runner).should == pending_build
      end

      it "does not pick build with different tag" do
        pending_build.tag_list = ["linux"]
        pending_build.save
        specific_runner.tag_list = ["win32"]
        service.execute(specific_runner).should be_false
      end

      it "picks build without tag" do
        service.execute(specific_runner).should == pending_build
      end

      it "does not pick build with tag" do
        pending_build.tag_list = ["linux"]
        pending_build.save
        service.execute(specific_runner).should be_false
      end

      it "pick build without tag" do
        specific_runner.tag_list = ["win32"]
        service.execute(specific_runner).should == pending_build
      end
    end

    context 'allow shared runners' do
      before do
        project.shared_runners_enabled = true
        project.save
      end

      context 'shared runner' do
        let(:build) { service.execute(shared_runner) }

        it { build.should be_kind_of(Build) }
        it { build.should be_valid }
        it { build.should be_running }
        it { build.runner.should == shared_runner }
      end

      context 'specific runner' do
        let(:build) { service.execute(specific_runner) }

        it { build.should be_kind_of(Build) }
        it { build.should be_valid }
        it { build.should be_running }
        it { build.runner.should == specific_runner }
      end
    end

    context 'disallow shared runners' do
      context 'shared runner' do
        let(:build) { service.execute(shared_runner) }

        it { build.should be_nil }
      end

      context 'specific runner' do
        let(:build) { service.execute(specific_runner) }

        it { build.should be_kind_of(Build) }
        it { build.should be_valid }
        it { build.should be_running }
        it { build.runner.should == specific_runner }
      end
    end
  end
end
