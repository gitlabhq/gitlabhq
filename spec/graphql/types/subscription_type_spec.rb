# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Subscription'] do
  it 'has the expected fields' do
    expected_fields = %i[
      issuable_assignees_updated
      issue_crm_contacts_updated
      issuable_title_updated
      issuable_description_updated
      issuable_labels_updated
      issuable_dates_updated
      merge_request_reviewers_updated
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
