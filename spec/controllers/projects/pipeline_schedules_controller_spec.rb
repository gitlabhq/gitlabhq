require 'spec_helper'

describe Projects::PipelineSchedulesController do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }
  let!(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project) }

  before do
    project.team << [user, :master]

    sign_in(user)
  end

  describe 'GET #index' do
    let!(:inactive_pipeline_schedule) { create(:ci_pipeline_schedule, :inactive, project: project) }
    let(:scope) { nil }

    it 'includes all pipeline schedules' do
      visit_pipelines_schedules

      expect(response).to have_http_status(:ok)
    end

    context 'scope is set to active' do
      let(:scope) { 'active' }

      before do
        visit_pipelines_schedules
      end

      it 'only shows active pipeline schedules' do
        expect(response).to have_http_status(:ok)
        expect(assigns(:schedules)).to include(pipeline_schedule)
        expect(assigns(:schedules)).not_to include(inactive_pipeline_schedule)
      end
    end

    def visit_pipelines_schedules
      get :index, namespace_id: project.namespace.to_param, project_id: project, scope: scope
    end
  end

  describe 'GET edit' do
    it 'loads the pipeline schedule' do
      get :edit, namespace_id: project.namespace.to_param, project_id: project, id: pipeline_schedule.id

      expect(response).to have_http_status(:ok)
      expect(assigns(:pipeline_schedule)).to eq(pipeline_schedule)
    end
  end
end
