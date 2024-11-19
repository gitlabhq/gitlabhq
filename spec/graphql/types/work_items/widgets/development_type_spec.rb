# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::Widgets::DevelopmentType, feature_category: :team_planning do
  it 'exposes the expected fields' do
    expected_fields = %i[type related_branches closing_merge_requests related_merge_requests
      will_auto_close_by_merge_request]

    expect(described_class).to have_graphql_fields(expected_fields).at_least
  end
end
