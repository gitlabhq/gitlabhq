# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects (JavaScript fixtures)', type: :controller do
  include ApiHelpers
  include JavaScriptFixturesHelpers

  runners_token = 'runnerstoken:intabulasreferre'

  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project, namespace: namespace, path: 'builds-project', runners_token: runners_token, avatar: fixture_file_upload('spec/fixtures/dk.png', 'image/png')) }
  let(:project_with_repo) { create(:project, :repository, description: 'Code and stuff', avatar: fixture_file_upload('spec/fixtures/dk.png', 'image/png')) }
  let(:project_variable_populated) { create(:project, namespace: namespace, path: 'builds-project2', runners_token: runners_token) }
  let(:user) { project.owner }

  render_views

  before(:all) do
    clean_frontend_fixtures('projects/')
  end

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

    context 'access token projects query' do
      before do
        project_variable_populated.add_maintainer(user)
      end

      before(:all) do
        clean_frontend_fixtures('graphql/projects/access_tokens')
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
end
