require 'spec_helper'

describe Projects::PipelineSchedulesController do
  set(:project) { create(:empty_project, :public) }
  let!(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project) }

  describe 'GET #index' do
    let(:scope) { nil }
    let!(:inactive_pipeline_schedule) do
      create(:ci_pipeline_schedule, :inactive, project: project)
    end

    it 'renders the index view' do
      visit_pipelines_schedules

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
    end

    context 'when the scope is set to active' do
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
    let(:user) { create(:user) }

    before do
      project.add_master(user)

      sign_in(user)
    end

    it 'loads the pipeline schedule' do
      get :edit, namespace_id: project.namespace.to_param, project_id: project, id: pipeline_schedule.id

      expect(response).to have_http_status(:ok)
      expect(assigns(:schedule)).to eq(pipeline_schedule)
    end
  end
end
