require 'spec_helper'

describe CiCd::GithubSetupService do
  let(:project) { create(:project) }

  subject do
    described_class.new(project)
  end

  describe '#execute' do
    it 'creates the webhook in the background' do
      expect(CreateGithubWebhookWorker).to receive(:perform_async).with(project.id)

      subject.execute
    end
  end
end
