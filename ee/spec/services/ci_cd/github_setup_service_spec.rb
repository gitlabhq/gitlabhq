require 'spec_helper'

describe CiCd::GithubSetupService do
  let(:repo_full_name) { "MyUser/my-project" }
  let(:api_token) { "abcdefghijk123" }
  let(:import_url) { "https://#{api_token}@github.com/#{repo_full_name}.git" }
  let(:credentials) { { user: api_token } }
  let(:project) do
    create(:project, import_source: repo_full_name,
                     import_url: import_url,
                     import_data_attributes: { credentials: credentials } )
  end

  subject do
    described_class.new(project)
  end

  describe '#execute' do
    it 'creates the webhook in the background' do
      expect(CreateGithubWebhookWorker).to receive(:perform_async).with(project.id)

      subject.execute
    end

    it 'sets up GithubService project integration' do
      allow(subject).to receive(:create_webhook)

      subject.execute

      expect(project.github_service).to be_active
    end
  end
end
