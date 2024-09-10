# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AbuseReportDiscussion'], feature_category: :team_planning do
  include GraphqlHelpers

  it 'exposes the expected fields' do
    expected_fields = %i[
      abuse_report
      created_at
      id
      notes
      reply_id
      resolvable
      resolved
      resolved_at
      resolved_by
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  specify { expect(described_class.graphql_name).to eq('AbuseReportDiscussion') }
end
