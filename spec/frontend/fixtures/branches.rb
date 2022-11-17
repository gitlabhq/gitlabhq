# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Branches (JavaScript fixtures)' do
  include JavaScriptFixturesHelpers

  let_it_be(:namespace) { create(:namespace, name: 'frontend-fixtures') }
  let_it_be(:project) { create(:project, :repository, namespace: namespace, path: 'branches-project') }
  let_it_be(:user) { project.first_owner }

  after(:all) do
    remove_repository(project)
  end

  describe Projects::BranchesController, '(JavaScript fixtures)', type: :controller do
    render_views

    before do
      sign_in(user)
    end

    it 'branches/new_branch.html' do
      get :new, params: {
        namespace_id: project.namespace.to_param,
        project_id: project
      }

      expect(response).to be_successful
    end
  end

  describe API::Branches, '(JavaScript fixtures)', type: :request do
    include ApiHelpers

    it 'api/branches/branches.json' do
      # The search query "ma" matches a few branch names in the test
      # repository with a variety of different properties, including:
      # - "master": default, protected
      # - "markdown": non-default, protected
      # - "many_files": non-default, not protected
      get api("/projects/#{project.id}/repository/branches?search=ma", user)

      expect(response).to be_successful
    end
  end
end
