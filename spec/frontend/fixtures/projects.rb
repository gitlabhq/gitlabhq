# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects (JavaScript fixtures)', type: :controller, feature_category: :groups_and_projects do
  include ApiHelpers
  include JavaScriptFixturesHelpers

  runners_token = 'runnerstoken:intabulasreferre'

  let(:namespace) { create(:namespace, name: 'frontend-fixtures') }
  let(:project) do
    create(
      :project,
      namespace: namespace,
      path: 'builds-project',
      runners_token: runners_token,
      avatar: fixture_file_upload('spec/fixtures/dk.png', 'image/png')
    )
  end

  let(:project_with_repo) do
    create(
      :project,
      :repository,
      description: 'Code and stuff',
      avatar: fixture_file_upload('spec/fixtures/dk.png', 'image/png')
    )
  end

  let(:project_variable_populated) do
    create(
      :project,
      namespace: namespace,
      path: 'builds-project2',
      runners_token: runners_token
    )
  end

  let(:user) { project.first_owner }

  render_views

  before do
    project_with_repo.add_maintainer(user)
    sign_in(user)
  end

  after do
    remove_repository(project)
  end

  describe ProjectsController, '(JavaScript fixtures)', type: :controller do
    it 'projects/overview.html' do
      get :show, params: {
        namespace_id: project_with_repo.namespace.to_param,
        id: project_with_repo
      }

      expect(response).to be_successful
    end

    it 'projects/edit.html' do
      get :edit, params: {
        namespace_id: project.namespace.to_param,
        id: project
      }

      expect(response).to be_successful
    end
  end

  describe GraphQL::Query, type: :request do
    include GraphqlHelpers

    context 'for access token projects query' do
      before do
        project_variable_populated.add_maintainer(user)
      end

      base_input_path = 'access_tokens/graphql/queries/'
      base_output_path = 'graphql/projects/access_tokens/'
      query_name = 'get_projects.query.graphql'

      it "#{base_output_path}#{query_name}.json" do
        query = get_graphql_query_as_string("#{base_input_path}#{query_name}")

        post_graphql(query, current_user: user, variables: { search: '', first: 2 })

        expect_graphql_errors_to_be_empty
      end
    end
  end

  describe 'Storage', feature_category: :consumables_cost_management do
    describe GraphQL::Query, type: :request do
      include GraphqlHelpers
      context 'for project storage statistics query' do
        before do
          project.statistics.update!(
            repository_size: 3_900_000,
            lfs_objects_size: 4_800_000,
            build_artifacts_size: 400_000,
            pipeline_artifacts_size: 400_000,
            container_registry_size: 3_900_000,
            wiki_size: 300_000,
            packages_size: 3_800_000,
            uploads_size: 900_000
          )
        end

        base_input_path = 'usage_quotas/storage/project/queries/'
        base_output_path = 'graphql/usage_quotas/storage/project/'
        query_name = 'project_storage.query.graphql'

        it "#{base_output_path}#{query_name}.json" do
          query = get_graphql_query_as_string("#{base_input_path}#{query_name}", ee: Gitlab.ee?)

          post_graphql(query, current_user: user, variables: { fullPath: project.full_path })

          expect_graphql_errors_to_be_empty
        end
      end
    end
  end
end

RSpec.describe API::Projects, '(JavaScript fixtures)', type: :request, feature_category: :groups_and_projects do
  include ApiHelpers
  include JavaScriptFixturesHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  before_all do
    project.add_maintainer(user)
  end

  before do
    sign_in(user)
  end

  it 'api/projects/put.json' do
    put api("/projects/#{project.id}", user), params: { name: "#{project.name} updated" }

    expect(response).to be_successful
  end

  it 'api/projects/put_validation_error.json' do
    put api("/projects/#{project.id}", user), params: { name: ".", description: 'a' * 2001 }

    expect(response).to have_gitlab_http_status(:bad_request)
  end
end
