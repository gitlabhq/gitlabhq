require 'spec_helper'

describe Projects::PipelinesSettingsController do
  set(:user) { create(:user) }
  set(:project_auto_devops) { create(:project_auto_devops) }
  let(:project) { project_auto_devops.project }

  before do
    project.add_master(user)

    sign_in(user)
  end

  describe 'GET show' do
    it 'redirects with 302 status code' do
      get :show, namespace_id: project.namespace, project_id: project

      expect(response).to have_gitlab_http_status(302)
    end
  end
end
