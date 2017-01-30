require 'spec_helper'

describe Admin::DashboardController do
  describe '#index' do
    it "allows an admin user to access the page" do
      sign_in(create(:user, :admin))
      get :index

      expect(response).to have_http_status(200)
    end

    it "does not allow an auditor user to access the page" do
      sign_in(create(:user, :auditor))
      get :index

      expect(response).to have_http_status(404)
    end

    it "does not allow a regular user to access the page" do
      sign_in(create(:user))
      get :index

      expect(response).to have_http_status(404)
    end
  end
end
