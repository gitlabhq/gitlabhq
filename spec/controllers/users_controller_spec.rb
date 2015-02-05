require 'spec_helper'

describe UsersController do
  let(:user)    { create(:user, username: "user1", name: "User 1", email: "user1@gitlab.com") }

  before do
    sign_in(user)
  end

  describe "GET #show" do
    render_views

    it "renders the show template" do
      get :show, username: user.username
      expect(response.status).to eq(200)
      expect(response).to render_template("show")
    end
  end

  describe "GET #calendar" do
    it "renders calendar" do
      get :calendar, username: user.username
      expect(response).to render_template("calendar")
    end
  end
end

