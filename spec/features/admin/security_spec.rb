require 'spec_helper'

describe "Admin::Projects", feature: true  do
  describe "GET /admin/projects" do
    subject { admin_projects_path }

    it { should be_allowed_for :admin }
    it { should be_denied_for :user }
    it { should be_denied_for :visitor }
  end

  describe "GET /admin/users" do
    subject { admin_users_path }

    it { should be_allowed_for :admin }
    it { should be_denied_for :user }
    it { should be_denied_for :visitor }
  end

  describe "GET /admin/hooks" do
    subject { admin_hooks_path }

    it { should be_allowed_for :admin }
    it { should be_denied_for :user }
    it { should be_denied_for :visitor }
  end
end
