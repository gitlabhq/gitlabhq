# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Jobs (JavaScript fixtures)' do
  include ApiHelpers
  include JavaScriptFixturesHelpers
  include GraphqlHelpers

  describe GraphQL::Query, type: :request do
    let_it_be(:user) { create(:user) }
    let_it_be(:groups) { create_list(:group, 4) }

    before_all do
      groups.each { |group| group.add_owner(user) }
    end

    query_name = 'search_namespaces_where_user_can_transfer_projects'
    query_extension = '.query.graphql'

    full_input_path = "projects/settings/graphql/queries/#{query_name}#{query_extension}"
    base_output_path = "graphql/projects/settings/#{query_name}"

    it "#{base_output_path}_page_1#{query_extension}.json" do
      query = get_graphql_query_as_string(full_input_path)

      post_graphql(query, current_user: user, variables: { first: 2 })

      expect_graphql_errors_to_be_empty
    end

    it "#{base_output_path}_page_2#{query_extension}.json" do
      query = get_graphql_query_as_string(full_input_path)

      post_graphql(query, current_user: user, variables: { first: 2 })

      post_graphql(
        query,
        current_user: user,
        variables: { first: 2, after: graphql_data_at('currentUser', 'groups', 'pageInfo', 'endCursor') }
      )

      expect_graphql_errors_to_be_empty
    end
  end
end
