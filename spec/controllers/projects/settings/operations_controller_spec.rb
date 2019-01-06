# frozen_string_literal: true

require 'spec_helper'

describe Projects::Settings::OperationsController do
  set(:user) { create(:user) }
  set(:project) { create(:project) }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  describe 'GET #show' do
    it 'returns 404' do
      get :show, params: project_params(project)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'PATCH #update' do
    it 'returns 404' do
      patch :update, params: project_params(project)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  private

  def project_params(project)
    { namespace_id: project.namespace, project_id: project }
  end
end
