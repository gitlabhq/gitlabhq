# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Dashboard access", feature_category: :system_access do
  include AccessMatchers

  describe "GET /dashboard" do
    subject { dashboard_projects_path }

    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /dashboard/issues" do
    subject { issues_dashboard_path }

    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /dashboard/merge_requests" do
    subject { merge_requests_dashboard_path }

    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /dashboard/projects/starred" do
    subject { starred_dashboard_projects_path }

    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /help" do
    subject { help_path }

    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_allowed_for :visitor }
  end

  describe "GET /projects/new" do
    it { expect(new_project_path).to be_allowed_for :admin }
    it { expect(new_project_path).to be_allowed_for :user }
    it { expect(new_project_path).to be_denied_for :visitor }
  end

  describe "GET /groups/new" do
    it { expect(new_group_path).to be_allowed_for :admin }
    it { expect(new_group_path).to be_allowed_for :user }
    it { expect(new_group_path).to be_denied_for :visitor }
  end

  describe "GET /dashboard/groups" do
    subject { dashboard_groups_path }

    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_denied_for :visitor }
  end
end
