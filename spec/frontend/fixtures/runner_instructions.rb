# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Runner Instructions (JavaScript fixtures)', feature_category: :runner do
  include ApiHelpers
  include JavaScriptFixturesHelpers
  include GraphqlHelpers

  query_path = 'ci/runner/components/registration/runner_instructions/graphql'
  fixtures_path = 'graphql/ci/runner/runner_instructions/'

  describe GraphQL::Query do
    describe 'get_runner_platforms.query.graphql', type: :request do
      let_it_be(:query) do
        get_graphql_query_as_string("#{query_path}/get_runner_platforms.query.graphql")
      end

      it "#{fixtures_path}get_runner_platforms.query.graphql.json" do
        post_graphql(query)

        expect_graphql_errors_to_be_empty
      end
    end

    describe 'get_runner_setup.query.graphql', type: :request do
      let_it_be(:query) do
        get_graphql_query_as_string("#{query_path}/get_runner_setup.query.graphql")
      end

      it "#{fixtures_path}get_runner_setup.query.graphql.json" do
        post_graphql(query, variables: { platform: 'linux', architecture: 'amd64' })

        expect_graphql_errors_to_be_empty
      end

      it "#{fixtures_path}get_runner_setup.query.graphql.windows.json" do
        post_graphql(query, variables: { platform: 'windows', architecture: 'amd64' })

        expect_graphql_errors_to_be_empty
      end
    end
  end
end
