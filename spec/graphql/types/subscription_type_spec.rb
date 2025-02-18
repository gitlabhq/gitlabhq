# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Subscription'], feature_category: :subscription_management do
  it 'has the expected fields' do
    expected_fields = %i[
      issuable_assignees_updated
      issue_crm_contacts_updated
      issuable_title_updated
      issuable_description_updated
      issuable_labels_updated
      issuable_dates_updated
      issuable_milestone_updated
      merge_request_reviewers_updated
      merge_request_merge_status_updated
      merge_request_approval_state_updated
      merge_request_diff_generated
      work_item_updated
      issuable_todo_updated
      user_merge_request_updated
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
