# frozen_string_literal: true

require 'spec_helper'

describe Admin::SessionsController, :do_not_mock_admin_mode do
  include_context 'custom session'

  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe '#new' do
    context 'for regular users' do
      it 'shows error page' do
        get :new

        expect(response).to have_gitlab_http_status(:not_found)
        expect(controller.send(:current_user_mode).admin_mode?).to be(false)
      end
    end

    context 'for admin users' do
      let(:user) { create(:admin) }

      it 'renders a password form' do
        get :new

        expect(response).to render_template :new
        expect(controller.send(:current_user_mode).admin_mode?).to be(false)
      end
    end
  end

  describe '#create' do
    context 'for regular users' do
      it 'shows error page' do
        post :create

        expect(response).to have_gitlab_http_status(:not_found)
        expect(controller.send(:current_user_mode).admin_mode?).to be(false)
      end
    end

    context 'for admin users' do
      let(:user) { create(:admin) }

      it 'sets admin mode with a valid password' do
        expect(controller.send(:current_user_mode).admin_mode?).to be(false)

        controller.store_location_for(:redirect, admin_root_path)
        post :create, params: { password: user.password }

        expect(response).to redirect_to admin_root_path
        expect(controller.send(:current_user_mode).admin_mode?).to be(true)
      end

      it 'fails with an invalid password' do
        expect(controller.send(:current_user_mode).admin_mode?).to be(false)

        controller.store_location_for(:redirect, admin_root_path)

        post :create, params: { password: '' }

        expect(response).to render_template :new
        expect(controller.send(:current_user_mode).admin_mode?).to be(false)
      end
    end
  end

  describe '#destroy' do
    context 'for regular users' do
      it 'shows error page' do
        get :destroy

        expect(response).to have_gitlab_http_status(404)
        expect(controller.send(:current_user_mode).admin_mode?).to be(false)
      end
    end

    context 'for admin users' do
      let(:user) { create(:admin) }

      it 'disables admin mode and redirects to main page' do
        expect(controller.send(:current_user_mode).admin_mode?).to be(false)
        post :create, params: { password: user.password }
        expect(controller.send(:current_user_mode).admin_mode?).to be(true)

        get :destroy

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(root_path)
        expect(controller.send(:current_user_mode).admin_mode?).to be(false)
      end
    end
  end
end
