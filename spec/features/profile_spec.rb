require 'spec_helper'

describe "Profile account page", feature: true do
  let(:user) { create(:user) }

  before do
    login_as :user
  end

  describe "when signup is enabled" do
    before do
      Gitlab.config.gitlab.stub(:signup_enabled).and_return(true)
      visit profile_account_path
    end

    it { page.should have_content("Remove account") }

    it "should delete the account" do
      expect { click_link "Delete account" }.to change {User.count}.by(-1)
      current_path.should == new_user_session_path
    end
  end

  describe "when signup is disabled" do
    before do
      Gitlab.config.gitlab.stub(:signup_enabled).and_return(false)
      visit profile_account_path
    end

    it "should not have option to remove account" do
      page.should_not have_content("Remove account")
      current_path.should == profile_account_path
    end
  end
end
