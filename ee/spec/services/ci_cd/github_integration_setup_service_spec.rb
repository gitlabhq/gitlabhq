require 'spec_helper'

describe CiCd::GithubIntegrationSetupService do
  let(:repo_full_name) { "MyUser/my-project" }
  let(:api_token) { "abcdefghijk123" }
  let(:import_url) { "https://#{api_token}@github.com/#{repo_full_name}.git" }
  let(:credentials) { { user: api_token } }
  let(:project) do
    create(:project, import_source: repo_full_name,
                     import_url: import_url,
                     import_data_attributes: { credentials: credentials } )
  end

  subject { described_class.new(project) }

  before do
    subject.execute
  end

  describe 'sets up GitHub service integration' do
    let(:integration) { project.github_service }

    specify 'with API token' do
      expect(integration.token).to eq api_token
    end

    specify 'with repo URL' do
      expect(integration.repository_url).to eq 'https://github.com/MyUser/my-project'
    end
  end
end
