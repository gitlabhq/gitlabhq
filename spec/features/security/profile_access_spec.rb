require 'spec_helper'

describe "Users Security" do
  describe "Project" do
    before do
      @u1 = create(:user)
    end

    describe "GET /login" do
      it { new_user_session_path.should_not be_404_for :visitor }
    end

    describe "GET /profile/keys" do
      subject { profile_keys_path }

      it { should be_allowed_for @u1 }
      it { should be_allowed_for :admin }
      it { should be_allowed_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /profile" do
      subject { profile_path }

      it { should be_allowed_for @u1 }
      it { should be_allowed_for :admin }
      it { should be_allowed_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /profile/account" do
      subject { profile_account_path }

      it { should be_allowed_for @u1 }
      it { should be_allowed_for :admin }
      it { should be_allowed_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /profile/design" do
      subject { design_profile_path }

      it { should be_allowed_for @u1 }
      it { should be_allowed_for :admin }
      it { should be_allowed_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /profile/history" do
      subject { history_profile_path }

      it { should be_allowed_for @u1 }
      it { should be_allowed_for :admin }
      it { should be_allowed_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /profile/notifications" do
      subject { profile_notifications_path }

      it { should be_allowed_for @u1 }
      it { should be_allowed_for :admin }
      it { should be_allowed_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /profile/groups" do
      subject { profile_groups_path }

      it { should be_allowed_for @u1 }
      it { should be_allowed_for :admin }
      it { should be_allowed_for :user }
      it { should be_denied_for :visitor }
    end
  end
end
