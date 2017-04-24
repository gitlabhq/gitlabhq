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

    before do
    end

    context 'without scope' do
      it 'includes all pipeline schedules' do
        visit_pipelines_schedules

        expect(assigns(:schedules)).to include(pipeline_schedule, inactive_pipeline_schedule)
      end

      it 'counts all schedules' do
        visit_pipelines_schedules

        expect(assigns(:all_schedules).count).to eq(2)
      end
    end

    context 'scope is set to active' do
      let(:scope) { 'active' }

      before do
        visit_pipelines_schedules
      end

      it 'only shows active pipeline schedules' do
        expect(assigns(:schedules)).to include(pipeline_schedule)
        expect(assigns(:schedules)).not_to include(inactive_pipeline_schedule)
      end

      it 'counts all schedules' do
        expect(assigns(:all_schedules).count).to eq(2)
      end
    end

    def visit_pipelines_schedules
      get :index, namespace_id: project.namespace.to_param, project_id: project, scope: scope
    end
  end

  describe 'GET edit' do
    it 'loads the pipeline schedule' do
      get :edit, namespace_id: project.namespace.to_param, project_id: project, id: pipeline_schedule.id

      expect(assigns(:pipeline_schedule)).to eq(pipeline_schedule)
    end
  end
end
