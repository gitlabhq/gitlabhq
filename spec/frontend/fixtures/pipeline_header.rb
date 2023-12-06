# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "GraphQL Pipeline Header", '(JavaScript fixtures)', type: :request, feature_category: :pipeline_composition do
  include ApiHelpers
  include GraphqlHelpers
  include JavaScriptFixturesHelpers

  let_it_be(:namespace) { create(:namespace, name: 'frontend-fixtures') }
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user) { project.first_owner }
  let_it_be(:commit) { create(:commit, project: project) }

  let(:query_path) { 'ci/pipeline_details/header/graphql/queries/get_pipeline_header_data.query.graphql' }

  context 'with successful pipeline' do
    let_it_be(:pipeline) do
      create(
        :ci_pipeline,
        :merged_result_pipeline,
        project: project,
        sha: commit.id,
        ref: 'master',
        user: user,
        name: 'Build pipeline',
        status: :success,
        duration: 7210,
        created_at: 2.hours.ago,
        started_at: 1.hour.ago,
        finished_at: Time.current,
        source: :schedule
      )
    end

    let_it_be(:builds) { create_list(:ci_build, 3, :success, pipeline: pipeline, ref: 'master') }

    it "graphql/pipelines/pipeline_header_success.json" do
      query = get_graphql_query_as_string(query_path)

      post_graphql(query, current_user: user, variables: { fullPath: project.full_path, iid: pipeline.iid })

      expect_graphql_errors_to_be_empty
    end
  end

  context 'with running pipeline' do
    let_it_be(:pipeline) do
      create(
        :ci_pipeline,
        project: project,
        sha: commit.id,
        ref: 'master',
        user: user,
        status: :running,
        created_at: 2.hours.ago,
        started_at: 1.hour.ago
      )
    end

    let_it_be(:build) { create(:ci_build, :running, pipeline: pipeline, ref: 'master') }

    it "graphql/pipelines/pipeline_header_running.json" do
      query = get_graphql_query_as_string(query_path)

      post_graphql(query, current_user: user, variables: { fullPath: project.full_path, iid: pipeline.iid })

      expect_graphql_errors_to_be_empty
    end
  end

  context 'with running pipeline and no permissions' do
    let_it_be(:pipeline) do
      create(
        :ci_pipeline,
        project: project,
        sha: commit.id,
        ref: 'master',
        user: user,
        status: :running,
        created_at: 2.hours.ago,
        started_at: 1.hour.ago
      )
    end

    let_it_be(:build) { create(:ci_build, :running, pipeline: pipeline, ref: 'master') }

    it "graphql/pipelines/pipeline_header_running_no_permissions.json" do
      guest = create(:user)
      project.add_guest(guest)

      query = get_graphql_query_as_string(query_path)

      post_graphql(query, current_user: guest, variables: { fullPath: project.full_path, iid: pipeline.iid })

      expect_graphql_errors_to_be_empty
    end
  end

  context 'with running pipeline and duration' do
    let_it_be(:pipeline) do
      create(
        :ci_pipeline,
        project: project,
        sha: commit.id,
        ref: 'master',
        user: user,
        status: :running,
        duration: 7210,
        created_at: 2.hours.ago,
        started_at: 1.hour.ago
      )
    end

    let_it_be(:build) { create(:ci_build, :running, pipeline: pipeline, ref: 'master') }

    it "graphql/pipelines/pipeline_header_running_with_duration.json" do
      query = get_graphql_query_as_string(query_path)

      post_graphql(query, current_user: user, variables: { fullPath: project.full_path, iid: pipeline.iid })

      expect_graphql_errors_to_be_empty
    end
  end

  context 'with failed pipeline' do
    let_it_be(:pipeline) do
      create(
        :ci_pipeline,
        project: project,
        sha: commit.id,
        ref: 'master',
        user: user,
        status: :failed,
        duration: 7210,
        started_at: 1.hour.ago,
        finished_at: Time.current
      )
    end

    let_it_be(:build) { create(:ci_build, :canceled, pipeline: pipeline, ref: 'master') }

    it "graphql/pipelines/pipeline_header_failed.json" do
      query = get_graphql_query_as_string(query_path)

      post_graphql(query, current_user: user, variables: { fullPath: project.full_path, iid: pipeline.iid })

      expect_graphql_errors_to_be_empty
    end
  end
end
