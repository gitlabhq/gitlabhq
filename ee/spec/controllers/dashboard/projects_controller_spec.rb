require 'spec_helper'

describe Dashboard::ProjectsController do
  include ExternalAuthorizationServiceHelpers

  before do
    sign_in create(:user)
  end

  describe '#index' do
    subject { get :index }

    it 'it works when the external authorization service is enabled' do
      enable_external_authorization_service_check

      get :index

      expect(response).to have_gitlab_http_status(200)
    end
  end
end
