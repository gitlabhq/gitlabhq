require 'spec_helper'

describe "Users Security", feature: true  do
  describe "Project" do
    before do
      @u1 = create(:user)
    end

    describe "GET /login" do
      it { expect(new_user_session_path).not_to be_404_for :visitor }
    end

    describe "GET /profile/keys" do
      subject { profile_keys_path }

      it { is_expected.to be_allowed_for @u1 }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_denied_for :visitor }
    end

    describe "GET /profile" do
      subject { profile_path }

      it { is_expected.to be_allowed_for @u1 }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_denied_for :visitor }
    end

    describe "GET /profile/account" do
      subject { profile_account_path }

      it { is_expected.to be_allowed_for @u1 }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_denied_for :visitor }
    end

    describe "GET /profile/design" do
      subject { design_profile_path }

      it { is_expected.to be_allowed_for @u1 }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_denied_for :visitor }
    end

    describe "GET /profile/history" do
      subject { history_profile_path }

      it { is_expected.to be_allowed_for @u1 }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_denied_for :visitor }
    end

    describe "GET /profile/notifications" do
      subject { profile_notifications_path }

      it { is_expected.to be_allowed_for @u1 }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_denied_for :visitor }
    end

    describe "GET /profile/groups" do
      subject { profile_groups_path }

      it { is_expected.to be_allowed_for @u1 }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_denied_for :visitor }
    end
  end
end
