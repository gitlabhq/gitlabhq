require 'spec_helper'

describe UnsubscribesController do
  let!(:user) { create :user, email: 'me@example.com' }

  describe "show" do
    it "responds with success" do
      get :show, email:  Base64.urlsafe_encode64('me@example.com')

      assert_response :success
    end

    it "behaves the same if email address isn't known in the system" do
      get :show, email: Base64.urlsafe_encode64('i@dont_exists.com')

      assert_response :success
    end
  end

  describe "create" do
    it "unsubscribes the connected user" do
      post :create, email: Base64.urlsafe_encode64('me@example.com')

      assert user.reload.admin_email_unsubscribed_at
    end

    # Don't tell if the email does not exists
    it "behaves the same if email address isn't known in the system" do
      post :create, email: Base64.urlsafe_encode64('i@dont_exists.com')

      assert_response :redirect
    end
  end
end
