# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Subscription'] do
  it 'has the expected fields' do
    expected_fields = %i[
      issuable_assignees_updated
    ]

    expect(described_class).to have_graphql_fields(*expected_fields).only
  end
end
