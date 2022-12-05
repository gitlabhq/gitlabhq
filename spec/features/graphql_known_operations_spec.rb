# frozen_string_literal: true

require 'spec_helper'

# We need to distinguish between known and unknown GraphQL operations. This spec
# tests that we set up Gitlab::Graphql::KnownOperations.default which requires
# integration of FE queries, webpack plugin, and BE.
RSpec.describe 'Graphql known operations', :js, feature_category: :integrations do
  around do |example|
    # Let's make sure we aren't receiving or leaving behind any side-effects
    # https://gitlab.com/gitlab-org/gitlab/-/jobs/1743294100
    ::Gitlab::Graphql::KnownOperations.instance_variable_set(:@default, nil)
    ::Gitlab::Webpack::GraphqlKnownOperations.clear_memoization!

    example.run

    ::Gitlab::Graphql::KnownOperations.instance_variable_set(:@default, nil)
    ::Gitlab::Webpack::GraphqlKnownOperations.clear_memoization!
  end

  it 'collects known Graphql operations from the code', :aggregate_failures do
    # Check that we include some arbitrary operation name we expect
    known_operations = Gitlab::Graphql::KnownOperations.default.operations.map(&:name)

    expect(known_operations).to include("searchProjects")
    expect(known_operations.length).to be > 20
    expect(known_operations).to all(match(%r{^[a-z]+}i))
  end
end
