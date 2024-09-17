# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AbuseReportNote'], feature_category: :team_planning do
  include GraphqlHelpers

  it 'exposes the expected fields' do
    expected_fields = %i[
      author
      body
      body_html
      body_first_line_html
      award_emoji
      created_at
      discussion
      id
      resolvable
      resolved
      resolved_at
      resolved_by
      updated_at
      url
      last_edited_at
      last_edited_by
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  specify { expect(described_class.graphql_name).to eq('AbuseReportNote') }
end
