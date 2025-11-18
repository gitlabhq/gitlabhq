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

  describe "GET /admin" do
    subject { admin_root_path }

    context 'when admin mode is enabled', :enable_admin_mode do
      it { is_expected.to be_allowed_for :admin }

      context 'when the admin user does not have permission' do
        before do
          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?).with(anything, :access_admin_area, :global).and_return(false)
        end

        it { is_expected.to be_denied_for :admin }
      end
    end

    context 'when admin mode is disabled' do
      it { is_expected.to be_denied_for :admin }
    end

    it { is_expected.to be_denied_for :user }
    it { is_expected.to be_denied_for :visitor }
  end
end
