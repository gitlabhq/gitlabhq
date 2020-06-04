# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ApplicationsController do
  let(:admin) { create(:admin) }
  let(:application) { create(:oauth_application, owner_id: nil, owner_type: nil) }

  before do
    sign_in(admin)
  end

  describe 'GET #index' do
    render_views

    it 'renders the application form' do
      get :index

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'GET #new' do
    it 'renders the application form' do
      get :new

      expect(response).to render_template :new
      expect(assigns[:scopes]).to be_kind_of(Doorkeeper::OAuth::Scopes)
    end
  end

  describe 'GET #edit' do
    it 'renders the application form' do
      get :edit, params: { id: application.id }

      expect(response).to render_template :edit
      expect(assigns[:scopes]).to be_kind_of(Doorkeeper::OAuth::Scopes)
    end
  end

  describe 'POST #create' do
    it 'creates the application' do
      create_params = attributes_for(:application, trusted: true, confidential: false)

      expect do
        post :create, params: { doorkeeper_application: create_params }
      end.to change { Doorkeeper::Application.count }.by(1)

      application = Doorkeeper::Application.last

      expect(response).to redirect_to(admin_application_path(application))
      expect(application).to have_attributes(create_params.except(:uid, :owner_type))
    end

    it 'renders the application form on errors' do
      expect do
        post :create, params: { doorkeeper_application: attributes_for(:application).merge(redirect_uri: nil) }
      end.not_to change { Doorkeeper::Application.count }

      expect(response).to render_template :new
      expect(assigns[:scopes]).to be_kind_of(Doorkeeper::OAuth::Scopes)
    end

    context 'when the params are for a confidential application' do
      it 'creates a confidential application' do
        create_params = attributes_for(:application, confidential: true)

        expect do
          post :create, params: { doorkeeper_application: create_params }
        end.to change { Doorkeeper::Application.count }.by(1)

        application = Doorkeeper::Application.last

        expect(response).to redirect_to(admin_application_path(application))
        expect(application).to have_attributes(create_params.except(:uid, :owner_type))
      end
    end
  end

  describe 'PATCH #update' do
    it 'updates the application' do
      doorkeeper_params = { redirect_uri: 'http://example.com/', trusted: true, confidential: false }

      patch :update, params: { id: application.id, doorkeeper_application: doorkeeper_params }

      application.reload

      expect(response).to redirect_to(admin_application_path(application))
      expect(application)
        .to have_attributes(redirect_uri: 'http://example.com/', trusted: true, confidential: false)
    end

    it 'renders the application form on errors' do
      patch :update, params: { id: application.id, doorkeeper_application: { redirect_uri: nil } }

      expect(response).to render_template :edit
      expect(assigns[:scopes]).to be_kind_of(Doorkeeper::OAuth::Scopes)
    end

    context 'when updating the application to be confidential' do
      it 'successfully sets the application to confidential' do
        doorkeeper_params = { confidential: true }

        patch :update, params: { id: application.id, doorkeeper_application: doorkeeper_params }

        expect(response).to redirect_to(admin_application_path(application))
        expect(application).to be_confidential
      end
    end
  end
end
