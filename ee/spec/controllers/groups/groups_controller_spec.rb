require 'spec_helper'

describe GroupsController do
  include ExternalAuthorizationServiceHelpers

  let(:user) { create(:user) }
  let(:group) { create(:group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  context 'with external authorization service enabled' do
    before do
      enable_external_authorization_service_check
    end

    describe 'GET #show' do
      it 'is successful' do
        get :show, id: group.to_param

        expect(response).to have_gitlab_http_status(200)
      end

      it 'does not allow other formats' do
        get :show, id: group.to_param, format: :atom

        expect(response).to have_gitlab_http_status(404)
      end
    end

    describe 'GET #edit' do
      it 'is successful' do
        get :edit, id: group.to_param

        expect(response).to have_gitlab_http_status(200)
      end
    end

    describe 'GET #new' do
      it 'is successful' do
        get :new

        expect(response).to have_gitlab_http_status(200)
      end
    end

    describe 'GET #index' do
      it 'is successful' do
        get :index

        # Redirects to the dashboard
        expect(response).to have_gitlab_http_status(302)
      end
    end

    describe 'POST #create' do
      it 'creates a group' do
        expect do
          post :create, group: { name: 'a name', path: 'a-name' }
        end.to change { Group.count }.by(1)
      end
    end

    describe 'PUT #update' do
      it 'updates a group' do
        expect do
          put :update, id: group.to_param, group: { name: 'world' }
        end.to change { group.reload.name }
      end
    end

    describe 'DELETE #destroy' do
      it 'deletes the group' do
        delete :destroy, id: group.to_param

        expect(response).to have_gitlab_http_status(302)
      end
    end
  end

  describe 'GET #activity' do
    subject { get :activity, id: group.to_param }

    it_behaves_like 'disabled when using an external authorization service'
  end

  describe 'GET #issues' do
    subject { get :issues, id: group.to_param }

    it_behaves_like 'disabled when using an external authorization service'
  end

  describe 'GET #merge_requests' do
    subject { get :merge_requests, id: group.to_param }

    it_behaves_like 'disabled when using an external authorization service'
  end
end
