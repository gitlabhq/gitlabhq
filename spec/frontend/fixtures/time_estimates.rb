# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Time estimates (GraphQL fixtures)', feature_category: :team_planning do
  describe GraphQL::Query, type: :request do
    include ApiHelpers
    include GraphqlHelpers
    include JavaScriptFixturesHelpers

    let_it_be(:developer) { create(:user) }

    context 'for issues time estimate' do
      let_it_be(:project) { create(:project_empty_repo, :public) }
      let_it_be(:issue) { create(:issue, project: project) }

      let(:query_path) { 'sidebar/queries/issue_set_time_estimate.mutation.graphql' }
      let(:query) { get_graphql_query_as_string(query_path) }

      before_all do
        project.add_developer(developer)
      end

      context 'when there are no errors while changing the time estimate' do
        it "graphql/issue_set_time_estimate_without_errors.json" do
          post_graphql(
            query,
            current_user: developer,
            variables: {
              input: {
                projectPath: project.full_path,
                iid: issue.iid.to_s,
                timeEstimate: '1d 2h'
              }
            }
          )

          expect_graphql_errors_to_be_empty
        end
      end

      context 'when there are errors while changing the time estimate' do
        it "graphql/issue_set_time_estimate_with_errors.json" do
          post_graphql(
            query,
            current_user: developer,
            variables: {
              input: {
                projectPath: project.full_path,
                iid: issue.iid.to_s,
                timeEstimate: '1egh'
              }
            }
          )

          expect_graphql_errors_to_include("timeEstimate must be formatted correctly, for example `1h 30m`")
        end
      end
    end
  end
end
