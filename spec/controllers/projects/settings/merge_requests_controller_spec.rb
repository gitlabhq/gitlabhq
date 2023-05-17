# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::MergeRequestsController do
  let(:project) { create(:project_empty_repo, :public) }
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

  describe '#update', :enable_admin_mode do
    render_views

    let(:admin) { create(:admin) }

    before do
      sign_in(admin)
    end

    it 'updates Fast Forward Merge attributes' do
      controller.instance_variable_set(:@project, project)

      params = {
        merge_method: :ff
      }

      put :update, params: {
        namespace_id: project.namespace,
        project_id: project.id,
        project: params
      }

      expect(response).to redirect_to project_settings_merge_requests_path(project)
      params.each do |param, value|
        expect(project.public_send(param)).to eq(value)
      end
    end
  end
end
