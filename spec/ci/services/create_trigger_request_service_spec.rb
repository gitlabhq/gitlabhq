require 'spec_helper'

describe CreateTriggerRequestService do
  let(:service) { CreateTriggerRequestService.new }
  let(:project) { FactoryGirl.create :project }
  let(:trigger) { FactoryGirl.create :trigger, project: project }

  describe :execute do
    context 'valid params' do
      subject { service.execute(project, trigger, 'master') }

      before do
        @commit = FactoryGirl.create :commit, project: project
      end

      it { subject.should be_kind_of(TriggerRequest) }
      it { subject.commit.should == @commit }
    end

    context 'no commit for ref' do
      subject { service.execute(project, trigger, 'other-branch') }

      it { subject.should be_nil }
    end

    context 'no builds created' do
      subject { service.execute(project, trigger, 'master') }

      before do
        FactoryGirl.create :commit_without_jobs, project: project
      end

      it { subject.should be_nil }
    end

    context 'for multiple commits' do
      subject { service.execute(project, trigger, 'master') }

      before do
        @commit1 = FactoryGirl.create :commit, committed_at: 2.hour.ago, project: project
        @commit2 = FactoryGirl.create :commit, committed_at: 1.hour.ago, project: project
        @commit3 = FactoryGirl.create :commit, committed_at: 3.hour.ago, project: project
      end

      context 'retries latest one' do
        it { subject.should be_kind_of(TriggerRequest) }
        it { subject.should be_persisted }
        it { subject.commit.should == @commit2 }
      end
    end
  end
end
