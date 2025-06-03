# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pipeline analytics (JavaScript fixtures)', feature_category: :fleet_visibility do
  include GraphqlHelpers
  include JavaScriptFixturesHelpers
  include ClickHouseHelpers

  describe 'Project CI/CD analytics', GraphQL::Query, :click_house, type: :request do
    let(:project) { project1 }
    let(:from_time) { 1.second.before(starting_time) }
    let(:to_time) { 1.second.before(ending_time) }

    include_context 'with pipelines executed on different projects'

    it "graphql/projects/pipelines/charts/graphql/queries/get_pipeline_analytics.query.graphql.json" do
      insert_ci_pipelines_to_click_house(pipelines)

      post_graphql(
        get_graphql_query_as_string('projects/pipelines/charts/graphql/queries/get_pipeline_analytics.query.graphql'),
        current_user: current_user,
        variables: { fullPath: project.full_path, fromTime: from_time, toTime: to_time }
      )

      expect_graphql_errors_to_be_empty
    end

    it "graphql/projects/pipelines/charts/graphql/queries/get_pipeline_analytics.empty.query.graphql.json" do
      post_graphql(
        get_graphql_query_as_string('projects/pipelines/charts/graphql/queries/get_pipeline_analytics.query.graphql'),
        current_user: current_user,
        variables: { fullPath: project.full_path, fromTime: from_time, toTime: to_time }
      )

      expect_graphql_errors_to_be_empty
    end
  end
end
