require 'spec_helper'

describe Groups::Settings::CiCdController do
  include ExternalAuthorizationServiceHelpers

  let(:group) { create(:group) }
  let(:user) { create(:user) }

  before do
    group.add_master(user)
    sign_in(user)
  end

  context 'with external authorization enabled' do
    before do
      enable_external_authorization_service_check
    end

    describe 'GET #show' do
      it 'renders show with 200 status code' do
        get :show, group_id: group

        expect(response).to have_gitlab_http_status(200)
      end
    end
  end
end
