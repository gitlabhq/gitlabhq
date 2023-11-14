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

      context 'when admin mode is enabled' do
        let!(:user) { create(:user, :admin) }

        before do
          Gitlab::Session.with_session(controller.session) do
            controller.current_user_mode.request_admin_mode!
            controller.current_user_mode.enable_admin_mode!(password: user.password)
          end
        end

        it 'renders the applications page' do
          get :index, params: { group_id: group }

          expect(response).to render_template :index
          expect(assigns[:scopes]).to be_kind_of(Doorkeeper::OAuth::Scopes)
        end
      end
    end

    %w[guest reporter developer maintainer].each do |role|
      context "when user is a #{role}" do
        before do
          group.send("add_#{role}", user)
        end

        it 'renders a 404' do
          get :index, params: { group_id: group }

          expect(response).to have_gitlab_http_status(:not_found)
        end

        context "when admin mode is enabled for the admin user who is a #{role} of a group" do
          let!(:user) { create(:user, :admin) }

          before do
            Gitlab::Session.with_session(controller.session) do
              controller.current_user_mode.request_admin_mode!
              controller.current_user_mode.enable_admin_mode!(password: user.password)
            end
          end

          it 'renders the applications page' do
            get :index, params: { group_id: group }

            expect(response).to render_template :index
            expect(assigns[:scopes]).to be_kind_of(Doorkeeper::OAuth::Scopes)
          end
        end
      end
    end
  end

  describe 'GET #edit' do
    context 'when user is owner' do
      before do
        group.add_owner(user)
      end

      it 'renders the edit application page' do
        get :edit, params: { group_id: group, id: application.id }

        expect(response).to render_template :edit
        expect(assigns[:scopes]).to be_kind_of(Doorkeeper::OAuth::Scopes)
      end

      context 'when admin mode is enabled' do
        let!(:user) { create(:user, :admin) }

        before do
          Gitlab::Session.with_session(controller.session) do
            controller.current_user_mode.request_admin_mode!
            controller.current_user_mode.enable_admin_mode!(password: user.password)
          end
        end

        it 'renders the edit application page' do
          get :edit, params: { group_id: group, id: application.id }

          expect(response).to render_template :edit
          expect(assigns[:scopes]).to be_kind_of(Doorkeeper::OAuth::Scopes)
        end
      end
    end

    %w[guest reporter developer maintainer].each do |role|
      context "when user is a #{role}" do
        before do
          group.send("add_#{role}", user)
        end

        it 'renders a 404' do
          get :edit, params: { group_id: group, id: application.id }

          expect(response).to have_gitlab_http_status(:not_found)
        end

        context "when admin mode is enabled for the admin user who is a #{role} of a group" do
          let!(:user) { create(:user, :admin) }

          before do
            Gitlab::Session.with_session(controller.session) do
              controller.current_user_mode.request_admin_mode!
              controller.current_user_mode.enable_admin_mode!(password: user.password)
            end
          end

          it 'renders the edit application page' do
            get :edit, params: { group_id: group, id: application.id }

            expect(response).to render_template :edit
            expect(assigns[:scopes]).to be_kind_of(Doorkeeper::OAuth::Scopes)
          end
        end
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

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template :show
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

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template :show
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

      context 'when admin mode is enabled' do
        let!(:user) { create(:user, :admin) }

        before do
          Gitlab::Session.with_session(controller.session) do
            controller.current_user_mode.request_admin_mode!
            controller.current_user_mode.enable_admin_mode!(password: user.password)
          end
        end

        it 'creates the application' do
          create_params = attributes_for(:application, trusted: false, confidential: false, scopes: ['api'])

          expect do
            post :create, params: { group_id: group, doorkeeper_application: create_params }
          end.to change { Doorkeeper::Application.count }.by(1)

          application = Doorkeeper::Application.last

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template :show
          expect(application).to have_attributes(create_params.except(:uid, :owner_type))
        end
      end
    end

    %w[guest reporter developer maintainer].each do |role|
      context "when user is a #{role}" do
        let(:create_params) { attributes_for(:application, trusted: true, confidential: false, scopes: ['api']) }

        before do
          group.send("add_#{role}", user)
        end

        it 'renders a 404' do
          post :create, params: { group_id: group, doorkeeper_application: create_params }

          expect(response).to have_gitlab_http_status(:not_found)
        end

        context "when admin mode is enabled for the admin user who is a #{role} of a group" do
          let!(:user) { create(:user, :admin) }

          before do
            Gitlab::Session.with_session(controller.session) do
              controller.current_user_mode.request_admin_mode!
              controller.current_user_mode.enable_admin_mode!(password: user.password)
            end
          end

          it 'creates the application' do
            create_params = attributes_for(:application, trusted: false, confidential: false, scopes: ['api'])

            expect do
              post :create, params: { group_id: group, doorkeeper_application: create_params }
            end.to change { Doorkeeper::Application.count }.by(1)

            application = Doorkeeper::Application.last

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template :show
            expect(application).to have_attributes(create_params.except(:uid, :owner_type))
          end
        end
      end
    end
  end

  describe 'PUT #renew' do
    context 'when user is owner' do
      before do
        group.add_owner(user)
      end

      let(:oauth_params) do
        {
          group_id: group,
          id: application.id
        }
      end

      subject { put :renew, params: oauth_params }

      it { is_expected.to have_gitlab_http_status(:ok) }
      it { expect { subject }.to change { application.reload.secret } }

      it 'returns the secret in json format' do
        subject

        expect(json_response['secret']).not_to be_nil
      end

      context 'when admin mode is enabled' do
        let!(:user) { create(:user, :admin) }

        before do
          Gitlab::Session.with_session(controller.session) do
            controller.current_user_mode.request_admin_mode!
            controller.current_user_mode.enable_admin_mode!(password: user.password)
          end
        end

        it { is_expected.to have_gitlab_http_status(:ok) }
        it { expect { subject }.to change { application.reload.secret } }

        it 'returns the secret in json format' do
          subject

          expect(json_response['secret']).not_to be_nil
        end
      end

      context 'when renew fails' do
        before do
          allow_next_found_instance_of(Doorkeeper::Application) do |application|
            allow(application).to receive(:save).and_return(false)
          end
        end

        it { expect { subject }.not_to change { application.reload.secret } }
        it { is_expected.to have_gitlab_http_status(:unprocessable_entity) }
      end
    end

    %w[guest reporter developer maintainer].each do |role|
      context "when user is a #{role}" do
        let(:oauth_params) do
          {
            group_id: group,
            id: application.id
          }
        end

        before do
          group.send("add_#{role}", user)
        end

        it 'renders a 404' do
          put :renew, params: oauth_params

          expect(response).to have_gitlab_http_status(:not_found)
        end

        context "when admin mode is enabled for the admin user who is a #{role} of a group" do
          let!(:user) { create(:user, :admin) }

          before do
            Gitlab::Session.with_session(controller.session) do
              controller.current_user_mode.request_admin_mode!
              controller.current_user_mode.enable_admin_mode!(password: user.password)
            end
          end

          it 'returns the secret in json format' do
            put :renew, params: oauth_params

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['secret']).not_to be_nil
          end
        end
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

      context 'when admin mode is enabled' do
        let!(:user) { create(:user, :admin) }

        before do
          Gitlab::Session.with_session(controller.session) do
            controller.current_user_mode.request_admin_mode!
            controller.current_user_mode.enable_admin_mode!(password: user.password)
          end
        end

        it 'updates the application' do
          doorkeeper_params = { redirect_uri: 'http://example.com/', trusted: true, confidential: false }

          patch :update, params: { group_id: group, id: application.id, doorkeeper_application: doorkeeper_params }

          application.reload

          expect(response).to redirect_to(group_settings_application_path(group, application))
          expect(application)
            .to have_attributes(redirect_uri: 'http://example.com/', trusted: false, confidential: false)
        end
      end
    end

    %w[guest reporter developer maintainer].each do |role|
      context "when user is a #{role}" do
        before do
          group.send("add_#{role}", user)
        end

        it 'renders a 404' do
          doorkeeper_params = { redirect_uri: 'http://example.com/', trusted: true, confidential: false }

          patch :update, params: { group_id: group, id: application.id, doorkeeper_application: doorkeeper_params }

          expect(response).to have_gitlab_http_status(:not_found)
        end

        context "when admin mode is enabled for the admin user who is a #{role} of a group" do
          let!(:user) { create(:user, :admin) }

          before do
            Gitlab::Session.with_session(controller.session) do
              controller.current_user_mode.request_admin_mode!
              controller.current_user_mode.enable_admin_mode!(password: user.password)
            end
          end

          it 'updates the application' do
            doorkeeper_params = { redirect_uri: 'http://example.com/', trusted: true, confidential: false }

            patch :update, params: { group_id: group, id: application.id, doorkeeper_application: doorkeeper_params }

            application.reload

            expect(response).to redirect_to(group_settings_application_path(group, application))
            expect(application)
              .to have_attributes(redirect_uri: 'http://example.com/', trusted: false, confidential: false)
          end
        end
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

      context 'when admin mode is enabled' do
        let!(:user) { create(:user, :admin) }

        before do
          Gitlab::Session.with_session(controller.session) do
            controller.current_user_mode.request_admin_mode!
            controller.current_user_mode.enable_admin_mode!(password: user.password)
          end
        end

        it 'deletes the application' do
          delete :destroy, params: { group_id: group, id: application.id }

          expect(Doorkeeper::Application.exists?(application.id)).to be_falsy
          expect(response).to redirect_to(group_settings_applications_url(group))
        end
      end
    end

    %w[guest reporter developer maintainer].each do |role|
      context "when user is a #{role}" do
        before do
          group.send("add_#{role}", user)
        end

        it 'renders a 404' do
          delete :destroy, params: { group_id: group, id: application.id }

          expect(response).to have_gitlab_http_status(:not_found)
        end

        context "when admin mode is enabled for the admin user who is a #{role} of a group" do
          let!(:user) { create(:user, :admin) }

          before do
            Gitlab::Session.with_session(controller.session) do
              controller.current_user_mode.request_admin_mode!
              controller.current_user_mode.enable_admin_mode!(password: user.password)
            end
          end

          it 'deletes the application' do
            delete :destroy, params: { group_id: group, id: application.id }

            expect(Doorkeeper::Application.exists?(application.id)).to be_falsy
            expect(response).to redirect_to(group_settings_applications_url(group))
          end
        end
      end
    end
  end
end
