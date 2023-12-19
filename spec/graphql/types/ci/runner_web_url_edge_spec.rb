# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::RunnerWebUrlEdge, feature_category: :fleet_visibility do
  specify { expect(described_class.graphql_name).to eq('RunnerWebUrlEdge') }

  it 'contains URL attributes' do
    expected_fields = %w[edit_url web_url]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
