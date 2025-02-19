# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::Widgets::ErrorTracking::StackTraceType, feature_category: :team_planning do
  it 'exposes the expected fields' do
    expected_fields = %i[filename absolute_path line_number column_number function context]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
