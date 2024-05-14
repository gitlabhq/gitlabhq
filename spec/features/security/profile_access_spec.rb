# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Profile access", feature_category: :user_management do
  include AccessMatchers

  describe "GET /-/user_settings/ssh_keys" do
    subject { user_settings_ssh_keys_path }

    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /-/user_settings/profile" do
    subject { user_settings_profile_path }

    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /-/profile/account" do
    subject { profile_account_path }

    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /-/profile/preferences" do
    subject { profile_preferences_path }

    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /-/profile/audit_log" do
    subject { audit_log_profile_path }

    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /-/profile/notifications" do
    subject { profile_notifications_path }

    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_denied_for :visitor }
  end
end
