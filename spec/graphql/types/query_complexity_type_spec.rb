# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['QueryComplexity'] do
  include GraphqlHelpers

  specify do
    expect(described_class).to have_graphql_fields(:limit, :score).only
  end

  it 'works when executed' do
    query = <<-GQL
      query {
        queryComplexity {
          score
          limit
        }

        currentUser {
          name
        }
      }
    GQL

    query_result = run_with_clean_state(query).to_h

    data = graphql_dig_at(query_result, :data, :queryComplexity)

    expect(data).to include(
      'score' => be > 0,
      'limit' => GitlabSchema::DEFAULT_MAX_COMPLEXITY
    )
  end
end
