# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ProjectsController do
  let!(:project) { create(:project, :public) }

  before do
    sign_in(create(:admin))
  end

  describe 'GET /projects' do
    render_views

    it 'retrieves the project for the given visibility level' do
      get :index, params: { visibility_level: [Gitlab::VisibilityLevel::PUBLIC] }

      expect(response.body).to match(project.name)
    end

    it 'does not retrieve the project' do
      get :index, params: { visibility_level: [Gitlab::VisibilityLevel::INTERNAL] }

      expect(response.body).not_to match(project.name)
    end

    it 'retrieves archived and non archived corrupted projects when last_repository_check_failed is true' do
      archived_corrupted_project = create(:project, :public, :archived, :last_repository_check_failed, name: 'CorruptedArchived', path: 'A')
      corrupted_project = create(:project, :public, :last_repository_check_failed, name: 'CorruptedOnly', path: 'C')

      get :index, params: { last_repository_check_failed: true }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).not_to match(project.name)
      expect(response.body).to match(archived_corrupted_project.name)
      expect(response.body).to match(corrupted_project.name)
    end

    it 'does not respond with projects pending deletion' do
      pending_delete_project = create(:project, pending_delete: true)

      get :index

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).not_to match(pending_delete_project.name)
      expect(response.body).to match(project.name)
    end

    it 'does not have N+1 queries', :use_clean_rails_memory_store_caching, :request_store do
      get :index

      control_count = ActiveRecord::QueryRecorder.new { get :index }.count

      create(:project)

      expect { get :index }.not_to exceed_query_limit(control_count)
    end
  end

  describe 'GET /projects.json' do
    render_views

    before do
      get :index, format: :json
    end

    it { is_expected.to respond_with(:success) }
  end

  describe 'GET /projects/:id' do
    render_views

    it 'renders show page' do
      get :show, params: { namespace_id: project.namespace.path, id: project.path }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to match(project.name)
    end
  end
end
