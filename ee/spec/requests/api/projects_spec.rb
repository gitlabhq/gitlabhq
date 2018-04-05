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
end
