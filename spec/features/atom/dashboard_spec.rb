require 'spec_helper'

describe "Dashboard Feed", feature: true  do
  describe "GET /" do
    let!(:user) { create(:user) }

    context "projects atom feed via private token" do
      it "should render projects atom feed" do
        visit dashboard_path(:atom, private_token: user.private_token)
        expect(page.body).to have_selector("feed title")
      end
    end
  end
end
