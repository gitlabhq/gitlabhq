# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Settings::ApplicationsController do
  let_it_be(:user)  { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:application) { create(:oauth_application, owner_id: group.id, owner_type: 'Namespace') }

  before do
    sign_in(user)
  end

  describe 'GET #index' do
    context 'when user is owner' do
      before do
        group.add_owner(user)
      end

      it 'renders the application form' do
        get :index, params: { group_id: group }

        expect(response).to render_template :index
        expect(assigns[:scopes]).to be_kind_of(Doorkeeper::OAuth::Scopes)
      end
    end

    context 'when user is not owner' do
      before do
        group.add_maintainer(user)
      end

      it 'renders a 404' do
        get :index, params: { group_id: group }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #edit' do
    context 'when user is owner' do
      before do
        group.add_owner(user)
      end

      it 'renders the application form' do
        get :edit, params: { group_id: group, id: application.id }

        expect(response).to render_template :edit
        expect(assigns[:scopes]).to be_kind_of(Doorkeeper::OAuth::Scopes)
      end
    end

    context 'when user is not owner' do
      before do
        group.add_maintainer(user)
      end

      it 'renders a 404' do
        get :edit, params: { group_id: group, id: application.id }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST #create' do
    context 'when user is owner' do
      before do
        group.add_owner(user)
      end

      it 'creates the application' do
        create_params = attributes_for(:application, trusted: false, confidential: false, scopes: ['api'])

        expect do
          post :create, params: { group_id: group, doorkeeper_application: create_params }
        end.to change { Doorkeeper::Application.count }.by(1)

        application = Doorkeeper::Application.last

        expect(response).to redirect_to(group_settings_application_path(group, application))
        expect(application).to have_attributes(create_params.except(:uid, :owner_type))
      end

      it 'renders the application form on errors' do
        expect do
          post :create, params: { group_id: group, doorkeeper_application: attributes_for(:application).merge(redirect_uri: nil) }
        end.not_to change { Doorkeeper::Application.count }

        expect(response).to render_template :index
        expect(assigns[:scopes]).to be_kind_of(Doorkeeper::OAuth::Scopes)
      end

      context 'when the params are for a confidential application' do
        it 'creates a confidential application' do
          create_params = attributes_for(:application, confidential: true, scopes: ['read_user'])

          expect do
            post :create, params: { group_id: group, doorkeeper_application: create_params }
          end.to change { Doorkeeper::Application.count }.by(1)

          application = Doorkeeper::Application.last

          expect(response).to redirect_to(group_settings_application_path(group, application))
          expect(application).to have_attributes(create_params.except(:uid, :owner_type))
        end
      end

      context 'when scopes are not present' do
        it 'renders the application form on errors' do
          create_params = attributes_for(:application, trusted: true, confidential: false)

          expect do
            post :create, params: { group_id: group, doorkeeper_application: create_params }
          end.not_to change { Doorkeeper::Application.count }

          expect(response).to render_template :index
        end
      end
    end

    context 'when user is not owner' do
      before do
        group.add_maintainer(user)
      end

      it 'renders a 404' do
        create_params = attributes_for(:application, trusted: true, confidential: false, scopes: ['api'])

        post :create, params: { group_id: group, doorkeeper_application: create_params }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'PATCH #update' do
    context 'when user is owner' do
      before do
        group.add_owner(user)
      end

      it 'updates the application' do
        doorkeeper_params = { redirect_uri: 'http://example.com/', trusted: true, confidential: false }

        patch :update, params: { group_id: group, id: application.id, doorkeeper_application: doorkeeper_params }

        application.reload

        expect(response).to redirect_to(group_settings_application_path(group, application))
        expect(application)
          .to have_attributes(redirect_uri: 'http://example.com/', trusted: false, confidential: false)
      end

      it 'renders the application form on errors' do
        patch :update, params: { group_id: group, id: application.id, doorkeeper_application: { redirect_uri: nil } }

        expect(response).to render_template :edit
        expect(assigns[:scopes]).to be_kind_of(Doorkeeper::OAuth::Scopes)
      end

      context 'when updating the application to be confidential' do
        it 'successfully sets the application to confidential' do
          doorkeeper_params = { confidential: true }

          patch :update, params: { group_id: group, id: application.id, doorkeeper_application: doorkeeper_params }

          application.reload

          expect(response).to redirect_to(group_settings_application_path(group, application))
          expect(application).to be_confidential
        end
      end
    end

    context 'when user is not owner' do
      before do
        group.add_maintainer(user)
      end

      it 'renders a 404' do
        doorkeeper_params = { redirect_uri: 'http://example.com/', trusted: true, confidential: false }

        patch :update, params: { group_id: group, id: application.id, doorkeeper_application: doorkeeper_params }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user is owner' do
      before do
        group.add_owner(user)
      end

      it 'deletes the application' do
        delete :destroy, params: { group_id: group, id: application.id }

        expect(Doorkeeper::Application.exists?(application.id)).to be_falsy
        expect(response).to redirect_to(group_settings_applications_url(group))
      end
    end

    context 'when user is not owner' do
      before do
        group.add_maintainer(user)
      end

      it 'renders a 404' do
        delete :destroy, params: { group_id: group, id: application.id }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
