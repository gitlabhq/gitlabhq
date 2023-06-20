# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admin::ApplicationSettings::SettingsHelper do
  describe '#inactive_projects_deletion_data' do
    let(:delete_inactive_projects) { true }
    let(:inactive_projects_delete_after_months) { 2 }
    let(:inactive_projects_min_size_mb) { 250 }
    let(:inactive_projects_send_warning_email_after_months) { 1 }

    let_it_be(:application_settings) { build(:application_setting) }

    before do
      stub_application_setting(delete_inactive_projects: delete_inactive_projects)
      stub_application_setting(inactive_projects_delete_after_months: inactive_projects_delete_after_months)
      stub_application_setting(inactive_projects_min_size_mb: inactive_projects_min_size_mb)
      stub_application_setting(
        inactive_projects_send_warning_email_after_months: inactive_projects_send_warning_email_after_months
      )
    end

    subject(:result) { helper.inactive_projects_deletion_data(application_settings) }

    it 'has the expected data' do
      expect(result).to eq({
        delete_inactive_projects: delete_inactive_projects.to_s,
        inactive_projects_delete_after_months: inactive_projects_delete_after_months,
        inactive_projects_min_size_mb: inactive_projects_min_size_mb,
        inactive_projects_send_warning_email_after_months: inactive_projects_send_warning_email_after_months
      })
    end
  end

  describe 'Code Suggestions for Self-Managed instances', feature_category: :code_suggestions do
    describe '#code_suggestions_token_explanation' do
      subject { helper.code_suggestions_token_explanation }

      it { is_expected.to include 'https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#create-a-personal-access-token' }
    end

    describe '#code_suggestions_agreement' do
      subject { helper.code_suggestions_agreement }

      it { is_expected.to include 'https://about.gitlab.com/handbook/legal/testing-agreement/' }
    end
  end
end
