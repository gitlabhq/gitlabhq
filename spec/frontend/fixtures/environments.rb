# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Environments (JavaScript fixtures)', feature_category: :environment_management do
  include ApiHelpers
  include JavaScriptFixturesHelpers
  include GraphqlHelpers

  let_it_be(:admin) { create(:admin, username: 'administrator', email: 'admin@example.gitlab.com') }
  let_it_be(:group) { create(:group, path: 'environments-group') }
  let_it_be(:project) { create(:project, :repository, group: group, path: 'environments-project') }

  let_it_be(:environment) { create(:environment, name: 'staging', project: project) }

  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:build) { create(:ci_build, :success, pipeline: pipeline) }

  let(:user) { create(:user) }
  let(:role) { :developer }

  describe GraphQL::Query, type: :request do
    environment_details_query_path = 'environments/graphql/queries/environment_details.query.graphql'

    context 'with no deployments' do
      it "graphql/#{environment_details_query_path}.empty.json" do
        query = get_graphql_query_as_string(environment_details_query_path)
        puts project.full_path
        puts environment.name
        post_graphql(
          query,
          current_user: admin,
          variables:
          {
            projectFullPath: project.full_path,
            environmentName: environment.name,
            pageSize: 10,
            deployment_details_enabled: true
          }
        )
        expect_graphql_errors_to_be_empty
      end
    end

    context 'with deployments' do
      let_it_be(:deployment) do
        create(:deployment, :success, environment: environment, deployable: nil)
      end

      let_it_be(:deployment_success) do
        create(:deployment, :success, environment: environment, deployable: build, finished_at: 1.hour.since)
      end

      let_it_be(:deployment_failed) do
        create(:deployment, :failed, environment: environment, deployable: build)
      end

      let_it_be(:deployment_running) do
        create(:deployment, :running, environment: environment, deployable: build)
      end

      it "graphql/#{environment_details_query_path}.json" do
        query = get_graphql_query_as_string(environment_details_query_path)

        post_graphql(
          query,
          current_user: admin,
          variables:
          {
            projectFullPath: project.full_path,
            environmentName: environment.name,
            pageSize: 10,
            deployment_details_enabled: true
          }
        )
        expect_graphql_errors_to_be_empty
      end
    end
  end
end
