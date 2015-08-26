# == Schema Information
#
# Table name: services
#
#  id         :integer          not null, primary key
#  type       :string(255)
#  title      :string(255)
#  project_id :integer          not null
#  created_at :datetime
#  updated_at :datetime
#  active     :boolean          default(FALSE), not null
#  properties :text
#

require 'spec_helper'

describe SlackService do
  describe "Associations" do
    it { should belong_to :project }
  end

  describe "Validations" do
    context "active" do
      before do
        subject.active = true
      end

      it { should validate_presence_of :webhook }
    end
  end

  describe "Execute" do
    let(:slack)   { SlackService.new }
    let(:project) { FactoryGirl.create :project }
    let(:commit)  { FactoryGirl.create :commit, project: project }
    let(:build)   { FactoryGirl.create :build, commit: commit, status: 'failed' }
    let(:webhook_url) { 'https://hooks.slack.com/services/SVRWFV0VVAR97N/B02R25XN3/ZBqu7xMupaEEICInN685' }
    let(:notify_only_broken_builds) { false }

    before do
      slack.stub(
        project: project,
        project_id: project.id,
        webhook: webhook_url,
        notify_only_broken_builds: notify_only_broken_builds
      )

      WebMock.stub_request(:post, webhook_url)
    end

    it "should call Slack API" do
      slack.execute(build)
      SlackNotifierWorker.drain

      WebMock.should have_requested(:post, webhook_url).once
    end
  end
end
