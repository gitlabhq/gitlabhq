# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RunnerProjectsController, feature_category: :fleet_visibility do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:source_project) { create(:project, organization: project.organization) }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  describe '#create' do
    subject(:send_create) do
      post :create, params: {
        namespace_id: group.path,
        project_id: project.path,
        runner_project: { runner_id: project_runner.id }
      }
    end

    context 'when assigning runner to another project' do
      let(:project_runner) { create(:ci_runner, :project, projects: [source_project]) }

      it 'redirects to the project runners page' do
        source_project.add_maintainer(user)

        send_create

        expect(flash[:success]).to be_present
        expect(response).to have_gitlab_http_status(:redirect)
        expect(response).to redirect_to project_runners_path(project)
      end
    end
  end

  describe '#destroy' do
    subject(:send_destroy) do
      delete :destroy, params: {
        namespace_id: request_project.namespace.path,
        project_id: request_project.path,
        id: runner_project_id
      }
    end

    context 'when unassigning runner from project' do
      # source_project is the owner and project is non-owner for success case
      let_it_be(:project_runner) { create(:ci_runner, :project, projects: [source_project, project]) }
      let(:runner_project_id) { project_runner.runner_projects.last.id }
      let(:request_project) { project }

      it 'redirects to the project runners page' do
        send_destroy

        expect(flash[:success]).to be_present
        expect(response).to have_gitlab_http_status(:redirect)
        expect(response).to redirect_to project_runners_path(request_project)
      end

      context 'when unassigning from owner project' do
        let(:request_project) { project_runner.owner }
        let(:runner_project_id) do
          project_runner.runner_projects.find_by(project: request_project).id
        end

        before do
          request_project.add_maintainer(user)
          send_destroy
        end

        it 'does not unassign the runner and redirects with a flash error' do
          expect(response).to have_gitlab_http_status(:redirect)
          expect(flash[:alert]).to be_present
          expect(response).to redirect_to project_runners_path(request_project)
        end
      end
    end
  end
end
