# frozen_string_literal: true

require 'spec_helper'

describe Profiles::NotificationsController do
  let(:user) do
    create(:user) do |user|
      user.emails.create(email: 'original@example.com')
      user.emails.create(email: 'new@example.com')
      user.notification_email = 'original@example.com'
      user.save!
    end
  end

  describe 'GET show' do
    it 'renders' do
      sign_in(user)

      get :show

      expect(response).to render_template :show
    end
  end

  describe 'POST update' do
    it 'updates only permitted attributes' do
      sign_in(user)

      put :update, params: { user: { notification_email: 'new@example.com', notified_of_own_activity: true, admin: true } }

      user.reload
      expect(user.notification_email).to eq('new@example.com')
      expect(user.notified_of_own_activity).to eq(true)
      expect(user.admin).to eq(false)
      expect(controller).to set_flash[:notice].to('Notification settings saved')
    end

    it 'shows an error message if the params are invalid' do
      sign_in(user)

      put :update, params: { user: { notification_email: '' } }

      expect(user.reload.notification_email).to eq('original@example.com')
      expect(controller).to set_flash[:alert].to('Failed to save new settings')
    end
  end
end
