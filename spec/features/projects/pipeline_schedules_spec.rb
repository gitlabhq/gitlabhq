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
        find_by_testid('edit-pipeline-schedule-btn').click

        expect(page).to have_content(s_('PipelineSchedules|Edit Scheduled Pipeline'))
        expect(page).to have_button(s_('PipelineSchedules|Save changes'))
      end

      context 'when the owner is nil' do
        before do
          pipeline_schedule.update!(owner_id: nil, description: "#{FFaker::Product.product_name} pipeline schedule")
          visit_pipelines_schedules
        end

        it 'shows the pipeline' do
          within_testid('pipeline-schedule-table-row') do
            expect(page).to have_content(pipeline_schedule.description)
          end
        end
      end
    end

    describe 'PATCH /projects/pipelines_schedules/:id/edit' do
      before do
        edit_pipeline_schedule
      end

      it 'displays existing properties' do
        description = find_field('schedule-description').value
        expect(description).to eq('pipeline schedule')
        expect(page).to have_button('master')
        expect(page).to have_button(_('Select timezone'))
      end

      it 'edits the scheduled pipeline' do
        fill_in 'schedule-description', with: 'my brand new description'

        save_pipeline_schedule

        expect(page).to have_content('my brand new description')
      end

      context 'when ref is nil' do
        before do
          pipeline_schedule.update_attribute(:ref, nil)
          edit_pipeline_schedule
        end

        it 'shows the pipeline schedule with default ref' do
          page.within('#schedule-target-branch-tag') do
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
          page.within('#schedule-target-branch-tag') do
            expect(first('.gl-button-text').text).to eq('master')
          end
        end
      end
    end
  end

  context 'logged in as a project maintainer' do
    before do
      project.add_maintainer(user)
      pipeline_schedule.update!(owner: maintainer)
      gitlab_sign_in(user)
    end

    describe 'GET /projects/pipeline_schedules' do
      before do
        visit_pipelines_schedules

        wait_for_requests
      end

      describe 'the view' do
        it 'displays the required information description' do
          within_testid('pipeline-schedule-table-row') do
            expect(page).to have_content('pipeline schedule')

            within_testid('next-run-cell') do
              expect(find('time')['title']).to include(pipeline_schedule.real_next_run.strftime('%B %-d, %Y'))
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
          find_by_testid('take-ownership-pipeline-schedule-btn').click

          page.within('#pipeline-take-ownership-modal') do
            click_button s_('PipelineSchedules|Take ownership')

            wait_for_requests
          end

          within_testid('pipeline-schedule-table-row') do
            expect(page).not_to have_content('No owner')
            expect(page).to have_link('Sidney Jones')
          end
        end

        it 'deletes the pipeline' do
          within_testid('pipeline-schedule-table-row') do
            click_button s_('PipelineSchedules|Delete scheduled pipeline')
          end

          accept_gl_confirm(button_text: s_('PipelineSchedules|Delete scheduled pipeline'))

          expect(page).not_to have_css('[data-testid="pipeline-schedule-table-row"]')
        end
      end

      context 'when ref is nil' do
        before do
          pipeline_schedule.update_attribute(:ref, nil)
          visit_pipelines_schedules
          wait_for_requests
        end

        it 'shows a list of the pipeline schedules with empty ref column' do
          target = find_by_testid('pipeline-schedule-target')

          within_testid('pipeline-schedule-table-row') do
            expect(target.text).to eq(s_('PipelineSchedules|None'))
          end
        end
      end

      context 'when ref is empty' do
        before do
          pipeline_schedule.update_attribute(:ref, '')
          visit_pipelines_schedules
          wait_for_requests
        end

        it 'shows a list of the pipeline schedules with empty ref column' do
          target = find_by_testid('pipeline-schedule-target')

          expect(target.text).to eq(s_('PipelineSchedules|None'))
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
        create_pipeline_schedule

        expect(page).to have_content("Cron timezone can't be blank")
      end
    end

    context 'when user creates a new pipeline schedule with variables' do
      before do
        visit_pipelines_schedules
        click_link 'New schedule'
        fill_in_schedule_form
        all('[data-testid="pipeline-form-ci-variable-key"]')[0].set('AAA')
        all('[data-testid="pipeline-form-ci-variable-value"]')[0].set('AAA123')
        all('[data-testid="pipeline-form-ci-variable-key"]')[1].set('BBB')
        all('[data-testid="pipeline-form-ci-variable-value"]')[1].set('BBB123')
        create_pipeline_schedule
      end

      it 'user sees the new variable in edit window' do
        find("body [data-testid='pipeline-schedule-table-row']:nth-child(1) .btn-group a[title='Edit scheduled pipeline']")
          .click

        expected_keys = [
          all("[data-testid='pipeline-form-ci-variable-key']")[0].value,
          all("[data-testid='pipeline-form-ci-variable-key']")[1].value
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
        first('[data-testid="pipeline-form-ci-variable-key"]').set('foo')
        first('[data-testid="pipeline-form-ci-variable-value"]').set('bar')
        save_pipeline_schedule
      end

      it 'user sees the updated variable' do
        first('[data-testid="edit-pipeline-schedule-btn"]').click

        expect(first('[data-testid="pipeline-form-ci-variable-key"]').value).to eq('foo')
        expect(first('[data-testid="pipeline-form-ci-variable-value"]').value).to eq('')

        click_button _('Reveal values')

        expect(first('[data-testid="pipeline-form-ci-variable-value"]').value).to eq('bar')
      end
    end

    context 'when user removes a variable of a pipeline schedule' do
      before do
        create(:ci_pipeline_schedule, project: project, owner: user).tap do |pipeline_schedule|
          create(:ci_pipeline_schedule_variable, key: 'AAA', value: 'AAA123', pipeline_schedule: pipeline_schedule)
        end

        visit_pipelines_schedules
        first('[data-testid="edit-pipeline-schedule-btn"]').click
        find_by_testid('remove-ci-variable-row').click
        save_pipeline_schedule
      end

      it 'user does not see the removed variable in edit window' do
        first('[data-testid="edit-pipeline-schedule-btn"]').click

        expect(first('[data-testid="pipeline-form-ci-variable-key"]').value).to eq('')
        expect(first('[data-testid="pipeline-form-ci-variable-value"]').value).to eq('')
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

  shared_examples 'when not logged in' do
    describe 'GET /projects/pipeline_schedules' do
      describe 'the view' do
        it 'does not show create schedule button' do
          visit_pipelines_schedules

          expect(page).not_to have_link('New schedule')
        end

        context 'when project is public' do
          let_it_be(:project) { create(:project, :repository, :public, public_builds: true) }

          it 'shows Pipelines Schedules page' do
            visit_pipelines_schedules

            expect(page).to have_selector(:css, '[data-testid="new-schedule-button"]')
          end

          context 'when public pipelines are disabled' do
            before do
              project.update!(public_builds: false)
              visit_pipelines_schedules
            end

            it 'shows Not Found page' do
              expect(page).to have_content('Page not found')
            end
          end
        end
      end
    end
  end

  it_behaves_like 'when not logged in'

  context 'logged in as non-member' do
    before do
      gitlab_sign_in(user)
    end

    it_behaves_like 'when not logged in'
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
    fill_in 'schedule-description', with: 'my fancy description'
    fill_in 'schedule_cron', with: '* 1 2 3 4'

    select_timezone
    select_target_branch
    find('body').click # close dropdown
  end
end
