require 'spec_helper'

describe Dashboard::ProjectsController do
  include ExternalAuthorizationServiceHelpers

  describe '#index' do
    context 'user not logged in' do
      it_behaves_like 'authenticates sessionless user', :index, :atom
    end

    context 'user logged in' do
      before do
        sign_in create(:user)
      end

      context 'external authorization' do
        it 'works when the external authorization service is enabled' do
          enable_external_authorization_service_check

          get :index

          expect(response).to have_gitlab_http_status(200)
        end
      end
    end
  end

  context 'json requests' do
    render_views

    let(:user) { create(:user) }

    before do
      sign_in(user)
    end

    describe 'GET /projects.json' do
      before do
        get :index, format: :json
      end

      it { is_expected.to respond_with(:success) }
    end

    describe 'GET /starred.json' do
      before do
        get :starred, format: :json
      end

      it { is_expected.to respond_with(:success) }
    end
  end
end
