# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Commit (JavaScript fixtures)', feature_category: :source_code_management do
  include JavaScriptFixturesHelpers

  let_it_be(:project, freeze: false) { create(:project, :repository) }
  let_it_be(:user, freeze: false)    { project.first_owner }
  let_it_be(:commit, freeze: false)  { project.commit("master") }

  before do
    allow(SecureRandom).to receive(:hex).and_return('securerandomhex:thereisnospoon')
  end

  after(:all) do
    remove_repository(project)
  end

  describe Projects::CommitController, '(JavaScript fixtures)', type: :controller do
    render_views

    before do
      sign_in(user)
    end

    it 'commit/show.html' do
      params = {
        namespace_id: project.namespace,
        project_id: project,
        id: commit.id
      }

      get :show, params: params

      expect(response).to be_successful
    end
  end

  describe API::Commits, '(JavaScript fixtures)', type: :request do
    include ApiHelpers

    it 'api/commits/commit.json' do
      get api("/projects/#{project.id}/repository/commits/#{commit.id}", user)

      expect(response).to be_successful
    end
  end
end
