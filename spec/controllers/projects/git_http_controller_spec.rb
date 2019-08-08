# frozen_string_literal: true

require 'spec_helper'

describe Projects::GitHttpController do
  describe 'HEAD #info_refs' do
    it 'returns 403' do
      project = create(:project, :public, :repository)

      head :info_refs, params: { namespace_id: project.namespace.to_param, project_id: project.path + '.git' }

      expect(response.status).to eq(403)
    end
  end

  describe 'GET #info_refs' do
    it 'returns 401 for unauthenticated requests to public repositories when http protocol is disabled' do
      stub_application_setting(enabled_git_access_protocol: 'ssh')
      project = create(:project, :public, :repository)

      get :info_refs, params: { service: 'git-upload-pack', namespace_id: project.namespace.to_param, project_id: project.path + '.git' }

      expect(response.status).to eq(401)
    end
  end
end
