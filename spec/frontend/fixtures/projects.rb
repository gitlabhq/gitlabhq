# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects (JavaScript fixtures)', type: :controller, feature_category: :groups_and_projects do
  include ApiHelpers
  include JavaScriptFixturesHelpers

  let(:namespace) { create(:namespace, name: 'frontend-fixtures') }
  let(:project) do
    create(
      :project,
      namespace: namespace,
      path: 'builds-project',
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

RSpec.describe GraphQL::Query, type: :request, feature_category: :groups_and_projects do
  include JavaScriptFixturesHelpers
  include GraphqlHelpers

  runners_token = 'runnerstoken:intabulasreferre'

  let_it_be(:project_variable_populated) do
    create(
      :project,
      runners_token: runners_token
    )
  end

  let_it_be(:project) { create(:project) }
  let_it_be(:project2) { create(:project) }

  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context 'for access token projects query' do
    before_all do
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

  context 'for your work -> projects -> contributed' do
    before_all do
      project.add_maintainer(user)
      project2.add_maintainer(user)
    end

    before do
      create(:push_event, project: project, author: user)
      create(:push_event, project: project2, author: user)
    end

    base_input_path = 'projects/your_work/graphql/queries/'
    input_query_name = 'user_projects.query.graphql'

    base_output_path = 'graphql/projects/your_work/'
    output_query_name = 'contributed_projects.query.graphql'

    it "#{base_output_path}#{output_query_name}.json" do
      query = get_graphql_query_as_string("#{base_input_path}#{input_query_name}")

      post_graphql(query, current_user: user, variables: { contributed: true })

      expect_graphql_errors_to_be_empty
    end
  end

  context 'for your work -> projects -> personal' do
    let_it_be(:user_with_namespace) { create(:user, :with_namespace) }
    let_it_be(:private_personal_project) { create(:project, :private, namespace: user_with_namespace.namespace) }

    before do
      sign_in(user_with_namespace)
    end

    base_input_path = 'projects/your_work/graphql/queries/'
    input_query_name = 'projects.query.graphql'

    base_output_path = 'graphql/projects/your_work/'
    output_query_name = 'personal_projects.query.graphql'

    it "#{base_output_path}#{output_query_name}.json" do
      query = get_graphql_query_as_string("#{base_input_path}#{input_query_name}")

      post_graphql(query, current_user: user_with_namespace, variables: { personal: true })

      expect_graphql_errors_to_be_empty
    end
  end

  context 'for your work -> projects -> member' do
    before_all do
      project.add_reporter(user)
      project2.add_reporter(user)
    end

    base_input_path = 'projects/your_work/graphql/queries/'
    input_query_name = 'projects.query.graphql'

    base_output_path = 'graphql/projects/your_work/'
    output_query_name = 'membership_projects.query.graphql'

    it "#{base_output_path}#{output_query_name}.json" do
      query = get_graphql_query_as_string("#{base_input_path}#{input_query_name}")

      post_graphql(query, current_user: user, variables: { membership: true })

      expect_graphql_errors_to_be_empty
    end
  end

  context 'for your work -> projects -> starred' do
    before_all do
      project.add_reporter(user)
      project2.add_reporter(user)
    end

    before do
      user.toggle_star(project)
      user.toggle_star(project2)
    end

    base_input_path = 'projects/your_work/graphql/queries/'
    input_query_name = 'user_projects.query.graphql'

    base_output_path = 'graphql/projects/your_work/'
    output_query_name = 'starred_projects.query.graphql'

    it "#{base_output_path}#{output_query_name}.json" do
      query = get_graphql_query_as_string("#{base_input_path}#{input_query_name}")

      post_graphql(query, current_user: user, variables: { starred: true })

      expect_graphql_errors_to_be_empty
    end
  end

  context 'for your work -> projects -> inactive' do
    let_it_be(:archived_project) { create(:project, :archived) }
    let_it_be(:pending_deletion_project) { create(:project, marked_for_deletion_at: 1.month.ago, pending_delete: true) }

    before_all do
      archived_project.add_reporter(user)
      pending_deletion_project.add_reporter(user)
    end

    base_input_path = 'projects/your_work/graphql/queries/'
    input_query_name = 'projects.query.graphql'

    base_output_path = 'graphql/projects/your_work/'
    output_query_name = 'inactive_projects.query.graphql'

    it "#{base_output_path}#{output_query_name}.json" do
      query = get_graphql_query_as_string("#{base_input_path}#{input_query_name}")

      post_graphql(query, current_user: user, variables: { archived: 'ONLY', membership: true })

      expect_graphql_errors_to_be_empty
    end
  end

  context 'for your work -> projects -> counts' do
    before_all do
      project.add_maintainer(user)
      project2.add_maintainer(user)
    end

    before do
      create(:push_event, project: project, author: user)
      create(:push_event, project: project2, author: user)
    end

    base_input_path = 'projects/your_work/graphql/queries/'
    base_output_path = 'graphql/projects/your_work/'
    query_name = 'project_counts.query.graphql'

    it "#{base_output_path}#{query_name}.json" do
      query = get_graphql_query_as_string("#{base_input_path}#{query_name}")

      post_graphql(query, current_user: user)

      expect_graphql_errors_to_be_empty
    end
  end
end
