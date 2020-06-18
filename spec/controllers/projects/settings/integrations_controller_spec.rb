# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::IntegrationsController do
  let(:project) { create(:project, :public) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET show' do
    it 'renders show with 200 status code' do
      get :show, params: { namespace_id: project.namespace, project_id: project }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:show)
    end
  end
end
