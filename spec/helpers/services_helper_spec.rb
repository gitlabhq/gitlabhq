# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServicesHelper do
  describe '#integration_form_data' do
    subject { helper.integration_form_data(integration) }

    context 'Jira service' do
      let(:integration) { build(:jira_service) }

      it 'includes Jira specific fields' do
        is_expected.to include(
          :id,
          :show_active,
          :activated,
          :type,
          :merge_request_events,
          :commit_events,
          :enable_comments,
          :comment_detail,
          :trigger_events,
          :fields,
          :inherit_from_id,
          :integration_level
        )
      end
    end
  end

  describe '#scoped_reset_integration_path' do
    let(:integration) { build_stubbed(:jira_service) }
    let(:group) { nil }

    subject { helper.scoped_reset_integration_path(integration, group: group) }

    context 'when no group is present' do
      it 'returns instance-level path' do
        is_expected.to eq(reset_admin_application_settings_integration_path(integration))
      end
    end

    context 'when group is present' do
      let(:group) { build_stubbed(:group) }

      it 'returns group-level path' do
        is_expected.to eq(reset_group_settings_integration_path(group, integration))
      end
    end
  end

  describe '#reset_integration?' do
    let(:group) { nil }

    subject { helper.reset_integration?(integration, group: group) }

    context 'when integration is existing record' do
      let_it_be(:integration) { create(:jira_service) }

      context 'when `reset_integrations` is not enabled' do
        it 'returns false' do
          stub_feature_flags(reset_integrations: false)

          is_expected.to eq(false)
        end
      end

      context 'when `reset_integrations` is enabled' do
        it 'returns true' do
          stub_feature_flags(reset_integrations: true)

          is_expected.to eq(true)
        end
      end

      context 'when `reset_integrations` is enabled for a group' do
        let(:group) { build_stubbed(:group) }

        it 'returns true' do
          stub_feature_flags(reset_integrations: group)

          is_expected.to eq(true)
        end
      end
    end

    context 'when integration is a new record' do
      let_it_be(:integration) { build(:jira_service) }

      context 'when `reset_integrations` is enabled' do
        it 'returns false' do
          stub_feature_flags(reset_integrations: true)

          is_expected.to eq(false)
        end
      end
    end
  end
end
