# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Todos (JavaScript fixtures)' do
  include JavaScriptFixturesHelpers

  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project_empty_repo, namespace: namespace, path: 'todos-project') }
  let(:user) { project.owner }
  let(:issue_1) { create(:issue, title: 'issue_1', project: project) }
  let!(:todo_1) { create(:todo, user: user, project: project, target: issue_1, created_at: 5.hours.ago) }
  let(:issue_2) { create(:issue, title: 'issue_2', project: project) }
  let!(:todo_2) { create(:todo, :done, user: user, project: project, target: issue_2, created_at: 50.hours.ago) }

  before(:all) do
    clean_frontend_fixtures('todos/')
  end

  after do
    remove_repository(project)
  end

  describe Dashboard::TodosController, '(JavaScript fixtures)', type: :controller do
    render_views

    before do
      sign_in(user)
    end

    it 'todos/todos.html' do
      get :index

      expect(response).to be_successful
    end
  end

  describe Projects::TodosController, '(JavaScript fixtures)', type: :controller do
    render_views

    before do
      sign_in(user)
    end

    it 'todos/todos.json' do
      post :create, params: {
        namespace_id: namespace,
        project_id: project,
        issuable_type: 'issue',
        issuable_id: issue_2.id
      }, format: 'json'

      expect(response).to be_successful
    end
  end
end
