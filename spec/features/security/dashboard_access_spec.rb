require 'spec_helper'

describe "Dashboard access"  do
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

  describe "GET /koding" do
    subject { koding_path }

    context 'with Koding enabled' do
      before do
        stub_application_setting(koding_enabled?: true)
      end

      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_denied_for :visitor }
    end
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

  describe "GET /profile/groups" do
    subject { dashboard_groups_path }

    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_denied_for :visitor }
  end
end
