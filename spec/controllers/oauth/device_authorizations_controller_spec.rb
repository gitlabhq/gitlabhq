# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::DeviceAuthorizationsController, feature_category: :system_access do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe "GET #index" do
    render_views

    context "when requested with HTML format" do
      it "renders the 'doorkeeper/device_authorization_grant/index' template" do
        get :index, format: :html
        expect(response).to render_template("doorkeeper/device_authorization_grant/index")
        expect(response).to have_gitlab_http_status(:ok)
      end

      it "uses the 'minimal' layout" do
        get :index, format: :html
        expect(response).to render_template(layout: 'minimal')
      end
    end

    context "when requested with JSON format" do
      it "returns a no content status" do
        get :index, format: :json
        expect(response).to have_gitlab_http_status(:no_content)
      end
    end
  end

  describe 'POST #confirm' do
    let(:user_code) { 'valid_user_code' }
    let(:device_grant) { instance_double('Doorkeeper::DeviceAuthorizationGrant::DeviceGrant', scopes: 'read write') }
    let(:invalid_user_code) { 'invalid_user_code' }

    before do
      allow(controller).to receive(:device_grant_model).and_return(Doorkeeper::DeviceAuthorizationGrant::DeviceGrant)
    end

    context 'with valid user_code' do
      before do
        allow(Doorkeeper::DeviceAuthorizationGrant::DeviceGrant).to receive(:find_by)
          .with(user_code: user_code).and_return(device_grant)
      end

      it 'assigns @scopes' do
        post :confirm, params: { user_code: user_code }, format: :html
        expect(assigns(:scopes)).to eq('read write')
      end

      it 'renders the authorize template' do
        post :confirm, params: { user_code: user_code }, format: :html
        expect(response).to render_template('doorkeeper/device_authorization_grant/authorize')
      end

      it 'responds with no content for JSON format' do
        post :confirm, params: { user_code: user_code }, format: :json
        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'with invalid user_code' do
      before do
        allow(Doorkeeper::DeviceAuthorizationGrant::DeviceGrant).to receive(:find_by)
          .with(user_code: invalid_user_code).and_return(nil)
      end

      it 'assigns @scopes as an empty string' do
        post :confirm, params: { user_code: invalid_user_code }, format: :html
        expect(assigns(:scopes)).to eq('')
      end

      it 'renders the authorize template' do
        post :confirm, params: { user_code: invalid_user_code }, format: :html
        expect(response).to render_template('doorkeeper/device_authorization_grant/authorize')
      end

      it 'responds with no content for JSON format' do
        post :confirm, params: { user_code: invalid_user_code }, format: :json
        expect(response).to have_gitlab_http_status(:no_content)
      end
    end
  end
end
