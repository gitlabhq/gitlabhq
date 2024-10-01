# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Timelogs (GraphQL fixtures)', feature_category: :team_planning do
  describe GraphQL::Query, type: :request do
    include ApiHelpers
    include GraphqlHelpers
    include JavaScriptFixturesHelpers

    let_it_be(:developer) { create(:user) }

    context 'for time tracking timelogs' do
      let_it_be(:project) { create(:project_empty_repo, :public) }
      let_it_be(:issue) { create(:issue, project: project) }

      let(:query_path) { 'time_tracking/components/queries/get_timelogs.query.graphql' }
      let(:query) { get_graphql_query_as_string(query_path) }

      before_all do
        project.add_developer(developer)
      end

      it "graphql/get_timelogs_empty_response.json" do
        post_graphql(query, current_user: developer, variables: { username: developer.username })

        expect_graphql_errors_to_be_empty
      end

      context 'with 20 or less timelogs' do
        let_it_be(:timelogs) { create_list(:timelog, 6, user: developer, issue: issue, time_spent: 4 * 60 * 60) }

        it "graphql/get_non_paginated_timelogs_response.json" do
          post_graphql(query, current_user: developer, variables: { username: developer.username })

          expect_graphql_errors_to_be_empty
        end
      end

      context 'with more than 20 timelogs' do
        let_it_be(:timelogs) { create_list(:timelog, 30, user: developer, issue: issue, time_spent: 4 * 60 * 60) }

        it "graphql/get_paginated_timelogs_response.json" do
          post_graphql(query, current_user: developer, variables: { username: developer.username, first: 25 })

          expect_graphql_errors_to_be_empty
        end
      end
    end
  end
end
