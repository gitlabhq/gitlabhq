# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin::Projects", feature_category: :system_access do
  include AccessMatchers

  describe "GET /admin/projects" do
    subject { admin_projects_path }

    context 'when admin mode is enabled', :enable_admin_mode do
      it { is_expected.to be_allowed_for :admin }
    end

    context 'when admin mode is disabled' do
      it { is_expected.to be_denied_for :admin }
    end

    it { is_expected.to be_denied_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /admin/users" do
    subject { admin_users_path }

    context 'when admin mode is enabled', :enable_admin_mode do
      it { is_expected.to be_allowed_for :admin }
    end

    context 'when admin mode is disabled' do
      it { is_expected.to be_denied_for :admin }
    end

    it { is_expected.to be_denied_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /admin/hooks" do
    subject { admin_hooks_path }

    context 'when admin mode is enabled', :enable_admin_mode do
      it { is_expected.to be_allowed_for :admin }
    end

    context 'when admin mode is disabled' do
      it { is_expected.to be_denied_for :admin }
    end

    it { is_expected.to be_denied_for :user }
    it { is_expected.to be_denied_for :visitor }
  end
end
