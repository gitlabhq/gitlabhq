# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects JSON endpoints (JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin, name: 'root') }
  let(:project) { create(:project, :repository) }

  before do
    project.add_maintainer(admin)
    sign_in(admin)
  end

  describe Projects::FindFileController, '(JavaScript fixtures)', type: :controller do
    it 'projects_json/files.json' do
      get :list,
        params: {
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: project.default_branch
        },
        format: 'json'

      expect(response).to be_successful
    end
  end

  describe Projects::CommitController, '(JavaScript fixtures)', type: :controller do
    it 'projects_json/pipelines_empty.json' do
      get :pipelines,
        params: {
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: project.commit(project.default_branch).id,
          format: 'json'
        }

      expect(response).to be_successful
    end
  end
end
