require 'spec_helper'

describe Admin::ProjectsController do
  let!(:project) { create(:project, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }

  before do
    sign_in(create(:admin))
  end

  describe 'GET /projects' do
    render_views

    it 'retrieves the project for the given visibility level' do
      get :index, visibility_levels: [Gitlab::VisibilityLevel::PUBLIC]
      expect(response.body).to match(project.name)
    end

    it 'does not retrieve the project' do
      get :index, visibility_levels: [Gitlab::VisibilityLevel::INTERNAL]
      expect(response.body).to_not match(project.name)
    end
  end
end
