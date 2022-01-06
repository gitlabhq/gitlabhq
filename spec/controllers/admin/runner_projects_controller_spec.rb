# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::RunnerProjectsController do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  before do
    sign_in(create(:admin))
  end

  describe '#create' do
    let(:project_id) { project.path }

    subject do
      post :create, params: {
        namespace_id: group.path,
        project_id: project_id,
        runner_project: { runner_id: project_runner.id }
      }
    end

    context 'assigning runner to same project' do
      let(:project_runner) { create(:ci_runner, :project, projects: [project]) }

      it 'redirects to the admin runner edit page' do
        subject

        expect(response).to have_gitlab_http_status(:redirect)
        expect(response).to redirect_to edit_admin_runner_url(project_runner)
      end
    end

    context 'assigning runner to another project' do
      let(:project_runner) { create(:ci_runner, :project, projects: [source_project]) }
      let(:source_project) { create(:project) }

      it 'redirects to the admin runner edit page' do
        subject

        expect(response).to have_gitlab_http_status(:redirect)
        expect(response).to redirect_to edit_admin_runner_url(project_runner)
      end
    end

    context 'for unknown project' do
      let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project]) }

      let(:project_id) { 0 }

      it 'shows 404 for unknown project' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
