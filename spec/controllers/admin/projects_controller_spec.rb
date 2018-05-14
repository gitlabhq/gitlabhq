require 'spec_helper'

describe Admin::ProjectsController do
  let!(:project) { create(:project, :public) }

  before do
    sign_in(create(:admin))
  end

  describe 'GET /projects' do
    render_views

    it 'retrieves the project for the given visibility level' do
      get :index, visibility_level: [Gitlab::VisibilityLevel::PUBLIC]

      expect(response.body).to match(project.name)
    end

    it 'does not retrieve the project' do
      get :index, visibility_level: [Gitlab::VisibilityLevel::INTERNAL]

      expect(response.body).not_to match(project.name)
    end

    it 'does not respond with projects pending deletion' do
      pending_delete_project = create(:project, pending_delete: true)

      get :index

      expect(response).to have_gitlab_http_status(200)
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
end
