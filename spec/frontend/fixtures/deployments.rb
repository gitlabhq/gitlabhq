# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Deployments (JavaScript fixtures)', feature_category: :continuous_delivery do
  include ApiHelpers
  include JavaScriptFixturesHelpers

  let_it_be(:admin) { create(:admin, username: 'administrator', email: 'admin@example.gitlab.com') }
  let_it_be(:group) { create(:group, path: 'deployment-group') }
  let_it_be(:project) { create(:project, :repository, group: group, path: 'releases-project') }
  let_it_be(:environment) do
    create(:environment, project: project, external_url: 'http://example.com')
  end

  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:build) { create(:ci_build, :manual, pipeline: pipeline) }

  let_it_be(:deployment) do
    create(:deployment,
      :success,
      environment: environment,
      deployable: build,
      created_at: Date.new(2019, 1, 1),
      finished_at: Date.new(2020, 1, 1))
  end

  describe GraphQL::Query, type: :request do
    include GraphqlHelpers

    deployment_query_path = 'deployments/graphql/queries/deployment.query.graphql'

    it "graphql/#{deployment_query_path}.json" do
      project.repository.add_tag(admin, SecureRandom.uuid, project.repository.commit.id)

      query = get_graphql_query_as_string(deployment_query_path)

      post_graphql(query, current_user: admin, variables: { fullPath: project.full_path, iid: deployment.iid })

      expect_graphql_errors_to_be_empty
      expect(graphql_data_at(:project, :deployment)).to be_present
    end

    environment_query_path = 'deployments/graphql/queries/environment.query.graphql'

    it "graphql/#{environment_query_path}.json" do
      query = get_graphql_query_as_string(environment_query_path)

      post_graphql(query, current_user: admin, variables: { fullPath: project.full_path, name: environment.name })

      expect_graphql_errors_to_be_empty
      expect(graphql_data_at(:project, :environment)).to be_present
    end
  end
end
