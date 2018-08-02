require 'spec_helper'

describe ExportCsvWorker do
  let(:user) { create(:user) }
  let(:project) { create(:project, creator: user) }

  def perform(params = {})
    described_class.new.perform(user.id, project.id, params)
  end

  it 'emails a CSV' do
    expect {perform}.to change(ActionMailer::Base.deliveries, :size).by(1)
  end

  it 'ensures that project_id is passed to issues_finder' do
    expect(IssuesFinder).to receive(:new).with(anything, hash_including(project_id: project.id)).and_call_original

    perform
  end

  it 'removes sort parameter' do
    expect(IssuesFinder).to receive(:new).with(anything, hash_not_including(:sort)).and_call_original

    perform
  end

  it 'converts controller string keys to symbol keys for IssuesFinder' do
    expect(IssuesFinder).to receive(:new).with(anything, hash_including(test_key: true)).and_call_original

    perform('test_key' => true)
  end
end
