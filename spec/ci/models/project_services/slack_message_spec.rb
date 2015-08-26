require 'spec_helper'

describe SlackMessage do
  subject { SlackMessage.new(commit) }

  let(:project) { FactoryGirl.create :project }

  context "One build" do
    let(:commit) { FactoryGirl.create(:commit_with_one_job, project: project) }

    let(:build) do 
      commit.create_builds
      commit.builds.first
    end

    context 'when build succeeded' do
      let(:color) { 'good' }

      it 'returns a message with succeeded build' do
        build.update(status: "success")

        subject.color.should == color
        subject.fallback.should include('Build')
        subject.fallback.should include("\##{build.id}")
        subject.fallback.should include('succeeded')
        subject.attachments.first[:fields].should be_empty
      end
    end

    context 'when build failed' do
      let(:color) { 'danger' }

      it 'returns a message with failed build' do
        build.update(status: "failed")

        subject.color.should == color
        subject.fallback.should include('Build')
        subject.fallback.should include("\##{build.id}")
        subject.fallback.should include('failed')
        subject.attachments.first[:fields].should be_empty
      end
    end
  end

  context "Several builds" do
    let(:commit) { FactoryGirl.create(:commit_with_two_jobs, project: project) }

    context 'when all matrix builds succeeded' do
      let(:color) { 'good' }

      it 'returns a message with success' do
        commit.create_builds
        commit.builds.update_all(status: "success")
        commit.reload

        subject.color.should == color
        subject.fallback.should include('Commit')
        subject.fallback.should include("\##{commit.id}")
        subject.fallback.should include('succeeded')
        subject.attachments.first[:fields].should be_empty
      end
    end

    context 'when one of matrix builds failed' do
      let(:color) { 'danger' }

      it 'returns a message with information about failed build' do
        commit.create_builds
        first_build = commit.builds.first
        second_build = commit.builds.last
        first_build.update(status: "success")
        second_build.update(status: "failed")
        
        subject.color.should == color
        subject.fallback.should include('Commit')
        subject.fallback.should include("\##{commit.id}")
        subject.fallback.should include('failed')
        subject.attachments.first[:fields].size.should == 1
        subject.attachments.first[:fields].first[:title].should == second_build.name
        subject.attachments.first[:fields].first[:value].should include("\##{second_build.id}")
      end
    end
  end
end
