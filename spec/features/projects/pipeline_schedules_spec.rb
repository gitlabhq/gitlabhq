require 'spec_helper'
include PipelineSchedulesHelper

feature 'Pipeline Schedules', :feature do
  set(:project) { create(:empty_project) }

  describe 'GET /projects/pipeline_schedules' do
    let!(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project) }
    let(:scope) { nil }
    let(:user) { create(:user) }

    before do
      project.add_master(user)

      login_as(user)
      visit_pipelines_schedules
    end

    it 'avoids N + 1 queries' do
      control_count = ActiveRecord::QueryRecorder.new { visit_pipelines_schedules }.count

      create_list(:ci_pipeline_schedule, 2, project: project)

      expect { visit_pipelines_schedules }.not_to exceed_query_limit(control_count)
    end

    context 'when the scope is set to active' do
      let(:scope) { 'active' }

      describe 'Table row' do
        it 'displays the description' do
          page.within('.pipeline-schedule-table-row') do
            expect(page).to have_content('pipeline schedule')
          end
        end
        
        it 'displays a link to the target branch' do
          page.within('.pipeline-schedule-table-row') do
            expect(page).to have_link('master')
          end
        end

        it 'displays the empty state for last pipeline' do
          page.within('.pipeline-schedule-table-row') do
            expect(page).to have_content('None')
          end
        end

        it 'displays next run timeago value' do
          page.within('.pipeline-schedule-table-row') do
            expect(page).to have_content('May 06, 2017')
          end
        end

        it 'displays next run timeago value' do
          page.within('.pipeline-schedule-table-row') do
            expect(page).to have_content('No owner')
          end
        end
      end

      describe 'Actions' do
        it 'creates a new scheduled pipeline' do
          click_link 'New Schedule'
          expect(page).to have_content('Schedule a new pipeline')
        end
        
        it 'changes ownership of the pipeline' do
          click_link 'Take ownership'
          page.within('.pipeline-schedule-table-row') do
            expect(page).not_to have_content('No owner')
            expect(page).to have_link('John Doe')
          end        
        end

        it 'edits the pipeline' do
          page.within('.pipeline-schedule-table-row') do
            click_link 'Edit'
          end       
  
          expect(page).to have_content('Edit Pipeline Schedule')
        end
        
        it 'deletes the pipeline' do
          click_link 'Delete'
          expect(page).not_to have_content('pipeline schedule')
        end
      end
      
    end
    
    def visit_pipelines_schedules
      visit namespace_project_pipeline_schedules_path(project.namespace, project, scope: scope)
    end
  end

  describe 'POST /projects/pipeline_schedules/new', focus: true do
    let!(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project) }
    let(:scope) { nil }
    let(:user) { create(:user) }

    before do
      project.add_master(user)
      login_as(user)
      create_pipeline_schedule
    end

    it 'it creates a new scheduled pipeline' do

    end

    it 'it prevents an invalid form from being submitted' do

    end
    
    def create_pipeline_schedule
      visit new_pipeline_schedule_path(project.namespace, project)
    end
  end

  describe 'POST /projects/pipelines_schedules/{id}/edit' do
    it 'it displays existing properties' do

    end

    it 'edits the scheduled pipeline' do

    end
  end
  

  def create_pipeline_schedule
    visit edit_pipeline_schedule_path(project.namespace, project)
  end
  
  def edit_pipeline_schedule
    visit edit_pipeline_schedule_path(pipeline_schedule)
  end
  
end
