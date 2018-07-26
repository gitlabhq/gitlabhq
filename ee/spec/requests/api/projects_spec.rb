require 'spec_helper'

describe API::Projects do
  include ExternalAuthorizationServiceHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  describe 'PUT /projects/:id' do
    before do
      enable_external_authorization_service_check
    end

    it 'updates the classification label when enabled' do
      put(api("/projects/#{project.id}", user), external_authorization_classification_label: 'new label')

      expect(response).to have_gitlab_http_status(200)

      expect(project.reload.external_authorization_classification_label).to eq('new label')
    end
  end

  describe 'GET /projects' do
    context 'filters by verification flags' do
      let(:project1) { create(:project, namespace: user.namespace) }

      it 'filters by :repository_verification_failed' do
        create(:repository_state, :repository_failed, project: project)
        create(:repository_state, :wiki_failed, project: project1)

        get api('/projects', user), repository_checksum_failed: true

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq project.id
      end

      it 'filters by :wiki_verification_failed' do
        create(:repository_state, :wiki_failed, project: project)
        create(:repository_state, :repository_failed, project: project1)

        get api('/projects', user), wiki_checksum_failed: true

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq project.id
      end
    end
  end
end
