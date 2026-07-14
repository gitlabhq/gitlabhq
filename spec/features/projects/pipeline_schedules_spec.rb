# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pipeline Schedules', :js, feature_category: :continuous_integration do
  include Spec::Support::Helpers::ModalHelpers

  let!(:project) { create(:project, :repository) }
  let!(:pipeline_schedule) { create(:ci_pipeline_schedule, :nightly, project: project) }
  let!(:pipeline) { create(:ci_pipeline, pipeline_schedule: pipeline_schedule, project: project) }
  let(:scope) { nil }
  let!(:user) { create(:user) }
  let!(:maintainer) { create(:user) }

  before do
    project.update!(ci_pipeline_variables_minimum_override_role: :developer)
  end

  context 'when logged in as the pipeline schedule owner' do
    before do
      project.add_developer(user)
      pipeline_schedule.update!(owner: user)
      sign_in(user)
    end

    describe 'GET /projects/pipeline_schedules' do
      it 'edits the pipeline' do
        visit_pipelines_schedules

        click_on 'Edit scheduled pipeline'

        expect(page).to have_content(s_('PipelineSchedules|Edit scheduled pipeline'))
        expect(page).to have_button(s_('PipelineSchedules|Save changes'))
      end

      context 'when the owner is nil' do
        before do
          pipeline_schedule.update!(owner_id: nil, description: "#{FFaker::Product.product_name} pipeline schedule")
        end

        it 'shows the pipeline' do
          visit_pipelines_schedules

          within_testid('pipeline-schedule-table-row') do
            expect(page).to have_content(pipeline_schedule.description)
          end
        end
      end
    end

    describe 'PATCH /projects/pipelines_schedules/:id/edit' do
      context 'with default state' do
        before do
          edit_pipeline_schedule
        end

        it 'displays existing properties' do
          expect(page).to have_field('Description', with: 'pipeline schedule')
          expect(page).to have_button('master')
          expect(page).to have_button('Select timezone')
        end

        it 'edits the scheduled pipeline' do
          fill_in 'Description', with: 'my brand new description'

          save_pipeline_schedule

          expect(page).to have_content('my brand new description')
        end
      end

      context 'when ref is nil' do
        before do
          pipeline_schedule.update_attribute(:ref, nil)
        end

        it 'shows the pipeline schedule with default ref' do
          edit_pipeline_schedule

          page.within('#schedule-target-branch-tag') do
            expect(page).to have_button('master')
          end
        end
      end

      context 'when ref is empty' do
        before do
          pipeline_schedule.update_attribute(:ref, '')
        end

        it 'shows the pipeline schedule with default ref' do
          edit_pipeline_schedule

          page.within('#schedule-target-branch-tag') do
            expect(page).to have_button('master')
          end
        end
      end
    end
  end

  context 'when logged in as a project maintainer' do
    before do
      project.add_maintainer(user)
      pipeline_schedule.update!(owner: maintainer)
      sign_in(user)
    end

    describe 'GET /projects/pipeline_schedules' do
      context 'with default state' do
        before do
          visit_pipelines_schedules
        end

        describe 'the view' do
          it 'displays the required information description' do
            within_testid('pipeline-schedule-table-row') do
              expect(page).to have_content('pipeline schedule')

              within_testid('next-run-cell') do
                # validate the format instead of the actual time because timezone issues were causing flaky tests
                expect(find('time')['title']).to match(/[A-Z][a-z]+ \d+, \d{4} at \d+:\d+:\d+ [AP]M [A-Z]{3,4}/)
              end

              expect(page).to have_link('master')

              within_testid('last-pipeline-status') do
                expect(find("a")['href']).to include(pipeline.id.to_s)
              end
            end
          end

          it 'creates a new scheduled pipeline' do
            click_link 'New schedule'

            expect(page).to have_content('Schedule a new pipeline')
          end

          it 'changes ownership of the pipeline' do
            click_on 'Take ownership of pipeline schedule'

            within_modal do
              click_button 'Take ownership'
            end

            within_testid('pipeline-schedule-table-row') do
              expect(page).not_to have_content('No owner')
              expect(page).to have_link('Sidney Jones')
            end
          end

          it 'deletes the pipeline schedule' do
            within_testid('pipeline-schedule-table-row') do
              click_on 'Delete scheduled pipeline'
            end

            within_modal do
              click_button 'Delete scheduled pipeline'
            end

            expect(page).not_to have_testid('pipeline-schedule-table-row', text: pipeline_schedule.description)
          end
        end
      end

      context 'when ref is nil' do
        before do
          pipeline_schedule.update_attribute(:ref, nil)
          visit_pipelines_schedules
        end

        it 'shows a list of the pipeline schedules with empty ref column' do
          within_testid('pipeline-schedule-table-row') do
            expect(page).to have_testid('pipeline-schedule-target', text: 'None', exact_text: true)
          end
        end
      end

      context 'when ref is empty' do
        before do
          pipeline_schedule.update_attribute(:ref, '')
          visit_pipelines_schedules
        end

        it 'shows a list of the pipeline schedules with empty ref column' do
          expect(page).to have_testid('pipeline-schedule-target', text: 'None', exact_text: true)
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
        create_pipeline_schedule

        expect(page).to have_content('my fancy description')
      end

      it 'prevents an invalid form from being submitted' do
        fill_in 'Description', with: 'my fancy description'
        create_pipeline_schedule

        expect(page).to have_content("Schedule a new pipeline")
      end
    end

    context 'when user creates a new pipeline schedule with variables' do
      before do
        visit_pipelines_schedules
        click_link 'New schedule'
        fill_in_schedule_form
        all('[data-testid="pipeline-form-ci-variable-key-field"]')[0].set('AAA')
        all('[data-testid="pipeline-form-ci-variable-value-field"]')[0].set('AAA123')
        all('[data-testid="pipeline-form-ci-variable-key-field"]')[1].set('BBB')
        all('[data-testid="pipeline-form-ci-variable-value-field"]')[1].set('BBB123')
        create_pipeline_schedule
      end

      it 'user sees the new variable in edit window' do
        find("body [data-testid='pipeline-schedule-table-row']:nth-child(1) .btn-group a[title='Edit scheduled pipeline']")
          .click

        expected_keys = [
          all("[data-testid='pipeline-form-ci-variable-key-field']")[0].value,
          all("[data-testid='pipeline-form-ci-variable-key-field']")[1].value
        ]
        expect(expected_keys).to include('AAA', 'BBB')
      end
    end

    context 'when user edits a variable of a pipeline schedule' do
      before do
        create(:ci_pipeline_schedule, project: project, owner: user).tap do |pipeline_schedule|
          create(:ci_pipeline_schedule_variable, key: 'AAA', value: 'AAA123', pipeline_schedule: pipeline_schedule)
        end

        visit_pipelines_schedules
        first('[data-testid="edit-pipeline-schedule-btn"]').click
        click_button _('Reveal values')
        first('[data-testid="pipeline-form-ci-variable-key-field"]').set('foo')
        first('[data-testid="pipeline-form-ci-variable-value-field"]').set('bar')
        save_pipeline_schedule
      end

      it 'user sees the updated variable' do
        first('[data-testid="edit-pipeline-schedule-btn"]').click

        expect(first('[data-testid="pipeline-form-ci-variable-key-field"]').value).to eq('foo')
        expect(first('[data-testid="pipeline-form-ci-variable-value-field"]').value).to eq('')

        click_button _('Reveal values')

        expect(first('[data-testid="pipeline-form-ci-variable-value-field"]').value).to eq('bar')
      end
    end

    context 'when user removes a variable of a pipeline schedule' do
      before do
        create(:ci_pipeline_schedule, project: project, owner: user).tap do |pipeline_schedule|
          create(:ci_pipeline_schedule_variable, key: 'AAA', value: 'AAA123', pipeline_schedule: pipeline_schedule)
        end

        visit_pipelines_schedules
        first('[data-testid="edit-pipeline-schedule-btn"]').click
        find_by_testid('remove-ci-variable-button-desktop').click
        save_pipeline_schedule
      end

      it 'user does not see the removed variable in edit window' do
        first('[data-testid="edit-pipeline-schedule-btn"]').click

        expect(first('[data-testid="pipeline-form-ci-variable-key-field"]').value).to eq('')
        expect(first('[data-testid="pipeline-form-ci-variable-value-field"]').value).to eq('')
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
        first('[data-testid="edit-pipeline-schedule-btn"]').click
        fill_in 'schedule_cron', with: '* 1 2 3 4'
        save_pipeline_schedule

        page.within(first('[data-testid="pipeline-schedule-table-row"]')) do
          expect(page).to have_css("[data-testid='next-run-cell'] time")
        end
      end
    end
  end

  shared_examples 'user without project access' do
    describe 'GET /projects/pipeline_schedules' do
      it 'does not show create schedule button' do
        visit_pipelines_schedules

        expect(page).not_to have_link('New schedule')
      end

      context 'when project is public' do
        let_it_be(:public_project, freeze: false) { create(:project, :repository, :public, public_builds: true) }

        it 'shows Pipelines Schedules page' do
          visit project_pipeline_schedules_path(public_project, scope: scope)
          expect(page).to have_selector(:css, '[data-testid="empty-state-new-schedule-button"]')
        end

        context 'when public pipelines are disabled' do
          before do
            public_project.update!(public_builds: false)
          end

          it 'shows Not Found page' do
            visit project_pipeline_schedules_path(public_project, scope: scope)
            expect(page).to have_content('Page not found')
          end
        end
      end
    end
  end

  it_behaves_like 'user without project access'

  context 'when logged in as non-member' do
    before do
      sign_in(user)
    end

    it_behaves_like 'user without project access'
  end

  def visit_new_pipeline_schedule
    visit new_project_pipeline_schedule_path(project)
  end

  def edit_pipeline_schedule
    visit edit_project_pipeline_schedule_path(project, pipeline_schedule)
  end

  def visit_pipelines_schedules
    visit project_pipeline_schedules_path(project, scope: scope)
  end

  def select_timezone
    find('#schedule-timezone .gl-new-dropdown-toggle').click
    find("li", text: "Arizona").click
  end

  def select_target_branch
    click_button 'master'
  end

  def create_pipeline_schedule
    click_button s_('PipelineSchedules|Create pipeline schedule')
  end

  def save_pipeline_schedule
    click_button s_('PipelineSchedules|Save changes')
  end

  def fill_in_schedule_form
    fill_in 'Description', with: 'my fancy description'
    fill_in 'schedule_cron', with: '* 1 2 3 4'

    select_timezone
    select_target_branch
    find('body').click # close dropdown
  end
end
