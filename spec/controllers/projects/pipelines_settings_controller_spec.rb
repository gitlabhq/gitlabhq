# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::PipelinesSettingsController do
  let_it_be(:user) { create(:user) }
  let_it_be(:project_auto_devops) { create(:project_auto_devops) }

  let(:project) { project_auto_devops.project }

  before do
    project.add_maintainer(user)

    sign_in(user)
  end

  describe 'GET show' do
    it 'redirects with 302 status code' do
      get :show, params: { namespace_id: project.namespace, project_id: project }

      expect(response).to have_gitlab_http_status(:found)
    end
  end
end
