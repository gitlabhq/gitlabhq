require 'spec_helper'

describe Public::UnsubscribesController do
  let!(:user) { create :user, email: 'me@example.com' }

  describe "show" do
    it "responds with success" do
      get :show, email: 'me@example', format: 'com'

      assert_response :success
    end
  end

  describe "create" do
    it "unsubscribes the connected user" do
      post :create, email: 'me@example', format: 'com'

      assert user.reload.admin_email_unsubscribed_at
    end
  end
end
