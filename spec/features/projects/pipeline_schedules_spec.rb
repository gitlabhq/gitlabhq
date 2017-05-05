require 'spec_helper'
include PipelineSchedulesHelper
include WaitForAjax

feature 'Pipeline Schedules', :feature do
  set(:project) { create(:project) }

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
  end

  describe 'POST /projects/pipeline_schedules/new', js: true do
    let!(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project) }
    let(:scope) { nil }
    let(:user) { create(:user) }

    before do
      project.add_master(user)
      
      login_as(user)

      visit_new_pipeline_schedule
    end

    it 'it creates a new scheduled pipeline' do
      fill_in_schedule_form
      save_pipeline_schedule

      expect(page).to have_content('my fancy description')
    end

    it 'it prevents an invalid form from being submitted' do
      save_pipeline_schedule
      expect(page).to have_content('This field is required')
    end
  end

  describe 'POST /projects/pipelines_schedules/{id}/edit', js: true do
    set(:project2) { create(:project) }

    let!(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project2) }
    let(:scope) { nil }
    let(:user) { create(:user) }

    before do
      project.add_master(user)
      login_as(user)
      namespace_project_pipeline_schedules_path
    end
    
    it 'it displays existing properties' do
      fill_in_schedule_form
      save_pipeline_schedule
      click_link 'Edit'

      expect(page).to have_content('* 1 2 3 4')
      expect(page).to have_content('my fancy description')
      expect(page).to have_content('master')
      expect(page).to have_content('American Samoa')
    end

    it 'edits the scheduled pipeline' do
      fill_in_schedule_form
      save_pipeline_schedule
      click_link 'Edit'
  
      fill_in 'schedule_description', with: 'my brand new description'

      save_pipeline_schedule
      expect(page).to have_content('my brand new description')
    end
  end
  

  def visit_new_pipeline_schedule
    visit_pipelines_schedules
    click_link 'New Schedule'
  end
  
  def edit_pipeline_schedule
    visit edit_pipeline_schedule_path(pipeline_schedule)
  end
  
  def visit_pipelines_schedules
    visit namespace_project_pipeline_schedules_path(project.namespace, project, scope: scope)
  end

  def select_timezone
    click_button 'Select a timezone'
    click_link 'American Samoa'
  end
  
  def select_target_branch
    click_button 'Select target branch'
    click_link 'master'
  end

  def save_pipeline_schedule
    click_button 'Save pipeline schedule'
  end
  
  def fill_in_schedule_form
    fill_in 'schedule_description', with: 'my fancy description'
    fill_in 'schedule_cron', with: '* 1 2 3 4'

    select_timezone
    select_target_branch
  end
end
