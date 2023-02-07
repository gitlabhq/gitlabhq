# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DeletedNote'], feature_category: :team_planning do
  it 'exposes the expected fields' do
    expected_fields = %i[
      id
      discussion_id
      last_discussion_note
    ]

    expect(described_class).to have_graphql_fields(*expected_fields).only
  end
end
