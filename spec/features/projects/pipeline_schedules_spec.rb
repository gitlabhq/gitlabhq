# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pipeline Schedules', :js, feature_category: :projects do
  include Spec::Support::Helpers::ModalHelpers

  let!(:project) { create(:project, :repository) }
  let!(:pipeline_schedule) { create(:ci_pipeline_schedule, :nightly, project: project) }
  let!(:pipeline) { create(:ci_pipeline, pipeline_schedule: pipeline_schedule, project: project) }
  let(:scope) { nil }
  let!(:user) { create(:user) }
  let!(:maintainer) { create(:user) }

  context 'with pipeline_schedules_vue feature flag turned off' do
    before do
      stub_feature_flags(pipeline_schedules_vue: false)
    end

    context 'logged in as the pipeline schedule owner' do
      before do
        project.add_developer(user)
        pipeline_schedule.update!(owner: user)
        gitlab_sign_in(user)
      end

      describe 'GET /projects/pipeline_schedules' do
        before do
          visit_pipelines_schedules
        end

        it 'edits the pipeline' do
          page.within('.pipeline-schedule-table-row') do
            click_link 'Edit'
          end

          expect(page).to have_content('Edit Pipeline Schedule')
        end
      end

      describe 'PATCH /projects/pipelines_schedules/:id/edit' do
        before do
          edit_pipeline_schedule
        end

        it 'displays existing properties' do
          description = find_field('schedule_description').value
          expect(description).to eq('pipeline schedule')
          expect(page).to have_button('master')
          expect(page).to have_button('Select timezone')
        end

        it 'edits the scheduled pipeline' do
          fill_in 'schedule_description', with: 'my brand new description'

          save_pipeline_schedule

          expect(page).to have_content('my brand new description')
        end

        context 'when ref is nil' do
          before do
            pipeline_schedule.update_attribute(:ref, nil)
            edit_pipeline_schedule
          end

          it 'shows the pipeline schedule with default ref' do
            page.within('[data-testid="schedule-target-ref"]') do
              expect(first('.gl-button-text').text).to eq('master')
            end
          end
        end

        context 'when ref is empty' do
          before do
            pipeline_schedule.update_attribute(:ref, '')
            edit_pipeline_schedule
          end

          it 'shows the pipeline schedule with default ref' do
            page.within('[data-testid="schedule-target-ref"]') do
              expect(first('.gl-button-text').text).to eq('master')
            end
          end
        end
      end
    end

    context 'logged in as a project maintainer' do
      before do
        project.add_maintainer(user)
        gitlab_sign_in(user)
      end

      describe 'GET /projects/pipeline_schedules' do
        before do
          visit_pipelines_schedules
        end

        describe 'The view' do
          it 'displays the required information description' do
            page.within('.pipeline-schedule-table-row') do
              expect(page).to have_content('pipeline schedule')
              expect(find("[data-testid='next-run-cell'] time")['title'])
                .to include(pipeline_schedule.real_next_run.strftime('%b %-d, %Y'))
              expect(page).to have_link('master')
              expect(page).to have_link("##{pipeline.id}")
            end
          end

          it 'creates a new scheduled pipeline' do
            click_link 'New schedule'

            expect(page).to have_content('Schedule a new pipeline')
          end

          it 'changes ownership of the pipeline' do
            click_button 'Take ownership'

            page.within('#pipeline-take-ownership-modal') do
              click_link 'Take ownership'
            end

            page.within('.pipeline-schedule-table-row') do
              expect(page).not_to have_content('No owner')
              expect(page).to have_link('Sidney Jones')
            end
          end

          it 'deletes the pipeline' do
            click_link 'Delete'

            accept_gl_confirm(button_text: 'Delete pipeline schedule')

            expect(page).not_to have_css(".pipeline-schedule-table-row")
          end
        end

        context 'when ref is nil' do
          before do
            pipeline_schedule.update_attribute(:ref, nil)
            visit_pipelines_schedules
          end

          it 'shows a list of the pipeline schedules with empty ref column' do
            expect(first('.branch-name-cell').text).to eq('')
          end
        end

        context 'when ref is empty' do
          before do
            pipeline_schedule.update_attribute(:ref, '')
            visit_pipelines_schedules
          end

          it 'shows a list of the pipeline schedules with empty ref column' do
            expect(first('.branch-name-cell').text).to eq('')
          end
        end
      end

      describe 'POST /projects/pipeline_schedules/new' do
        before do
          visit_new_pipeline_schedule
        end

        it 'sets defaults for timezone and target branch' do
          expect(page).to have_button('master')
          expect(page).to have_button('Select timezone')
        end

        it 'creates a new scheduled pipeline' do
          fill_in_schedule_form
          save_pipeline_schedule

          expect(page).to have_content('my fancy description')
        end

        it 'prevents an invalid form from being submitted' do
          save_pipeline_schedule

          expect(page).to have_content('This field is required')
        end
      end

      context 'when user creates a new pipeline schedule with variables' do
        before do
          visit_pipelines_schedules
          click_link 'New schedule'
          fill_in_schedule_form
          all('[name="schedule[variables_attributes][][key]"]')[0].set('AAA')
          all('[name="schedule[variables_attributes][][secret_value]"]')[0].set('AAA123')
          all('[name="schedule[variables_attributes][][key]"]')[1].set('BBB')
          all('[name="schedule[variables_attributes][][secret_value]"]')[1].set('BBB123')
          save_pipeline_schedule
        end

        it 'user sees the new variable in edit window', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/397040' do
          find(".content-list .pipeline-schedule-table-row:nth-child(1) .btn-group a[title='Edit']").click
          page.within('.ci-variable-list') do
            expect(find(".ci-variable-row:nth-child(1) .js-ci-variable-input-key").value).to eq('AAA')
            expect(find(".ci-variable-row:nth-child(1) .js-ci-variable-input-value", visible: false).value).to eq('AAA123')
            expect(find(".ci-variable-row:nth-child(2) .js-ci-variable-input-key").value).to eq('BBB')
            expect(find(".ci-variable-row:nth-child(2) .js-ci-variable-input-value", visible: false).value).to eq('BBB123')
          end
        end
      end

      context 'when user edits a variable of a pipeline schedule' do
        before do
          create(:ci_pipeline_schedule, project: project, owner: user).tap do |pipeline_schedule|
            create(:ci_pipeline_schedule_variable, key: 'AAA', value: 'AAA123', pipeline_schedule: pipeline_schedule)
          end

          visit_pipelines_schedules
          find(".content-list .pipeline-schedule-table-row:nth-child(1) .btn-group a[title='Edit']").click
          find('.js-ci-variable-list-section .js-secret-value-reveal-button').click
          first('.js-ci-variable-input-key').set('foo')
          first('.js-ci-variable-input-value').set('bar')
          click_button 'Save pipeline schedule'
        end

        it 'user sees the updated variable in edit window' do
          find(".content-list .pipeline-schedule-table-row:nth-child(1) .btn-group a[title='Edit']").click
          page.within('.ci-variable-list') do
            expect(find(".ci-variable-row:nth-child(1) .js-ci-variable-input-key").value).to eq('foo')
            expect(find(".ci-variable-row:nth-child(1) .js-ci-variable-input-value", visible: false).value).to eq('bar')
          end
        end
      end

      context 'when user removes a variable of a pipeline schedule' do
        before do
          create(:ci_pipeline_schedule, project: project, owner: user).tap do |pipeline_schedule|
            create(:ci_pipeline_schedule_variable, key: 'AAA', value: 'AAA123', pipeline_schedule: pipeline_schedule)
          end

          visit_pipelines_schedules
          find(".content-list .pipeline-schedule-table-row:nth-child(1) .btn-group a[title='Edit']").click
          find('.ci-variable-list .ci-variable-row-remove-button').click
          click_button 'Save pipeline schedule'
        end

        it 'user does not see the removed variable in edit window' do
          find(".content-list .pipeline-schedule-table-row:nth-child(1) .btn-group a[title='Edit']").click
          page.within('.ci-variable-list') do
            expect(find(".ci-variable-row:nth-child(1) .js-ci-variable-input-key").value).to eq('')
            expect(find(".ci-variable-row:nth-child(1) .js-ci-variable-input-value", visible: false).value).to eq('')
          end
        end
      end

      context 'when active is true and next_run_at is NULL' do
        before do
          create(:ci_pipeline_schedule, project: project, owner: user).tap do |pipeline_schedule|
            pipeline_schedule.update_attribute(:next_run_at, nil) # Consequently next_run_at will be nil
          end
        end

        it 'user edit and recover the problematic pipeline schedule' do
          visit_pipelines_schedules
          find(".content-list .pipeline-schedule-table-row:nth-child(1) .btn-group a[title='Edit']").click
          fill_in 'schedule_cron', with: '* 1 2 3 4'
          click_button 'Save pipeline schedule'

          page.within('.pipeline-schedule-table-row:nth-child(1)') do
            expect(page).to have_css("[data-testid='next-run-cell'] time")
          end
        end
      end
    end

    context 'logged in as non-member' do
      before do
        gitlab_sign_in(user)
      end

      describe 'GET /projects/pipeline_schedules' do
        before do
          visit_pipelines_schedules
        end

        describe 'The view' do
          it 'does not show create schedule button' do
            expect(page).not_to have_link('New schedule')
          end
        end
      end
    end

    context 'not logged in' do
      describe 'GET /projects/pipeline_schedules' do
        before do
          visit_pipelines_schedules
        end

        describe 'The view' do
          it 'does not show create schedule button' do
            expect(page).not_to have_link('New schedule')
          end
        end
      end
    end
  end

  context 'with pipeline_schedules_vue feature flag turned on' do
    context 'logged in as a project maintainer' do
      before do
        project.add_maintainer(maintainer)
        pipeline_schedule.update!(owner: user)
        gitlab_sign_in(maintainer)
      end

      describe 'GET /projects/pipeline_schedules' do
        before do
          visit_pipelines_schedules

          wait_for_requests
        end

        describe 'The view' do
          it 'displays the required information description' do
            page.within('[data-testid="pipeline-schedule-table-row"]') do
              expect(page).to have_content('pipeline schedule')
              expect(find("[data-testid='next-run-cell'] time")['title'])
                .to include(pipeline_schedule.real_next_run.strftime('%b %-d, %Y'))
              expect(page).to have_link('master')
              expect(find("[data-testid='last-pipeline-status'] a")['href']).to include(pipeline.id.to_s)
            end
          end

          it 'changes ownership of the pipeline' do
            click_button 'Take ownership'

            page.within('#pipeline-take-ownership-modal') do
              click_button 'Take ownership'

              wait_for_requests
            end

            page.within('[data-testid="pipeline-schedule-table-row"]') do
              expect(page).not_to have_content('No owner')
              expect(page).to have_link('Sidney Jones')
            end
          end

          it 'runs the pipeline' do
            click_button 'Run pipeline schedule'

            wait_for_requests

            expect(page).to have_content("Successfully scheduled a pipeline to run. Go to the Pipelines page for details.")
          end

          it 'deletes the pipeline' do
            click_button 'Delete pipeline schedule'

            accept_gl_confirm(button_text: 'Delete pipeline schedule')

            expect(page).not_to have_css('[data-testid="pipeline-schedule-table-row"]')
          end
        end
      end
    end

    context 'logged in as non-member' do
      before do
        gitlab_sign_in(user)
      end

      describe 'GET /projects/pipeline_schedules' do
        before do
          visit_pipelines_schedules

          wait_for_requests
        end

        describe 'The view' do
          it 'does not show create schedule button' do
            expect(page).not_to have_link('New schedule')
          end
        end
      end
    end

    context 'not logged in' do
      describe 'GET /projects/pipeline_schedules' do
        before do
          visit_pipelines_schedules

          wait_for_requests
        end

        describe 'The view' do
          it 'does not show create schedule button' do
            expect(page).not_to have_link('New schedule')
          end
        end
      end
    end
  end

  def visit_new_pipeline_schedule
    visit new_project_pipeline_schedule_path(project, pipeline_schedule)
  end

  def edit_pipeline_schedule
    visit edit_project_pipeline_schedule_path(project, pipeline_schedule)
  end

  def visit_pipelines_schedules
    visit project_pipeline_schedules_path(project, scope: scope)
  end

  def select_timezone
    find('[data-testid="schedule-timezone"] .dropdown-toggle').click
    find("button", text: "Arizona").click
  end

  def select_target_branch
    click_button 'master'
  end

  def save_pipeline_schedule
    click_button 'Save pipeline schedule'
  end

  def fill_in_schedule_form
    fill_in 'schedule_description', with: 'my fancy description'
    fill_in 'schedule_cron', with: '* 1 2 3 4'

    select_timezone
    select_target_branch
    find('body').click # close dropdown
  end
end
