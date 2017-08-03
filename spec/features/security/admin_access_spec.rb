require 'spec_helper'

describe "Admin::Projects"  do
  include AccessMatchers

  describe "GET /admin/projects" do
    subject { admin_projects_path }

    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_denied_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /admin/users" do
    subject { admin_users_path }

    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_denied_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /admin/hooks" do
    subject { admin_hooks_path }

    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_denied_for :user }
    it { is_expected.to be_denied_for :visitor }
  end
end
