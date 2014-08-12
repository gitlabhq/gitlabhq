require 'spec_helper'

describe UnsubscribesController do
  let!(:user) { create :user, email: 'me@example.com' }

  describe "show" do
    it "responds with success" do
      get :show, email: 'me@example', format: 'com'

      assert_response :success
    end

    it "behaves the same if email address isn't known in the system" do
      get :show, email: 'i@dont_exists', format: 'com'

      assert_response :success
    end
  end

  describe "create" do
    it "unsubscribes the connected user" do
      post :create, email: 'me@example', format: 'com'

      assert user.reload.admin_email_unsubscribed_at
    end

    # Don't tell if the email does not exists
    it "behaves the same if email address isn't known in the system" do
      post :create, email: 'i@dont_exists', format: 'com'

      assert_response :redirect
    end
  end
end
