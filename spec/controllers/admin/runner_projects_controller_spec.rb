# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::RunnerProjectsController, feature_category: :fleet_visibility do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe '#create' do
    let(:project_id) { project.path }

    subject(:send_create) do
      post :create, params: {
        namespace_id: group.path,
        project_id: project_id,
        runner_project: { runner_id: project_runner.id }
      }
    end

    context 'when assigning to another project' do
      let(:project_runner) { create(:ci_runner, :project, projects: [source_project]) }
      let_it_be(:source_project) { create(:project, organization: project.organization) }

      it 'redirects to the admin runner edit page' do
        send_create

        expect(flash[:success]).to be_present
        expect(response).to have_gitlab_http_status(:redirect)
        expect(response).to redirect_to edit_admin_runner_url(project_runner)
      end
    end

    context 'when assigning to same project' do
      let(:project_runner) { create(:ci_runner, :project, projects: [project]) }

      it 'redirects to the admin runner edit page' do
        send_create

        expect(flash[:alert]).to be_present
        expect(response).to have_gitlab_http_status(:redirect)
        expect(response).to redirect_to edit_admin_runner_url(project_runner)
      end
    end

    context 'when assigning to an unknown project' do
      let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project]) }

      let(:project_id) { 0 }

      it 'shows 404 for unknown project' do
        send_create

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#destroy' do
    let_it_be(:project2) { create(:project) }
    let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project, project2]) }

    let(:project_id) { project.path }

    subject(:send_destroy) do
      delete :destroy, params: {
        namespace_id: group.path,
        project_id: project_id,
        id: runner_project_id
      }
    end

    context 'when unassigning runner from project' do
      let(:runner_project_id) { project_runner.runner_projects.last.id }

      it 'redirects to the admin runner edit page' do
        send_destroy

        expect(response).to have_gitlab_http_status(:redirect)
        expect(response).to redirect_to edit_admin_runner_url(project_runner)
      end
    end

    context 'when unassigning from unknown project' do
      let(:runner_project_id) { non_existing_record_id }

      it 'shows 404 for unknown project runner relationship' do
        send_destroy

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
