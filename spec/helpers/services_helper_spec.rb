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
          :inherit_from_id
        )
      end
    end
  end
end
