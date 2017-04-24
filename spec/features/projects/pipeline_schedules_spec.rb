require 'spec_helper'

feature 'Pipeline Schedules', :feature do
  let!(:project) { create(:empty_project) }

  describe 'GET /projects/pipeline_schedules' do
    let!(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project) }
    let(:scope) { nil }
    let(:user) { create(:user) }

    before do
      project.team << [user, :master]

      login_as(user)
      visit_pipelines_schedules
    end

    it 'avoids N + 1 queries' do
      control_count = ActiveRecord::QueryRecorder.new { visit_pipelines_schedules }.count

      create_list(:ci_pipeline_schedule, 2, project: project)

      expect { visit_pipelines_schedules }.not_to exceed_query_limit(control_count)
    end

    context 'scope is set to active' do
      let(:scope) { 'active' }

      it 'lets bryce write a new test' do

      end
    end

    def visit_pipelines_schedules
      visit namespace_project_pipeline_schedules_path(project.namespace, project, scope: scope)
    end
  end
end
