# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin Runners", :freeze_time, feature_category: :fleet_visibility do
  include Features::SortingHelpers
  include Features::RunnersHelpers
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:admin) { create(:admin) }

  before do
    sign_in(admin)
    enable_admin_mode!(admin)
  end

  describe "Admin Runners page", :js do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:project) { create(:project, namespace: namespace, creator: user) }

    describe "runners creation and registration" do
      before do
        visit admin_runners_path
      end

      it 'shows a create button' do
        expect(page).to have_link s_('Runner|New instance runner'), href: new_admin_runner_path
      end

      it_behaves_like "shows and resets runner registration token" do
        let(:dropdown_text) { s_('Runners|Register an instance runner') }
        let(:registration_token) { Gitlab::CurrentSettings.runners_registration_token }
      end
    end

    context "when there are runners" do
      context "with an instance runner" do
        let_it_be(:instance_runner) { create(:ci_runner, :instance) }

        before do
          visit admin_runners_path
        end

        it_behaves_like 'shows runner summary and navigates to details' do
          let(:runner) { instance_runner }
          let(:runner_page_path) { admin_runner_path(instance_runner) }
        end

        it_behaves_like 'pauses, resumes and deletes a runner' do
          let(:runner) { instance_runner }
        end

        it 'shows an instance badge' do
          within_runner_row(instance_runner.id) do
            expect(page).to have_selector '.badge', text: s_('Runners|Instance')
          end
        end
      end

      context "with multiple runners" do
        before do
          create(:ci_runner, :instance, :online)
          create(:ci_runner, :instance, :offline)
          create(:ci_runner, :instance, :stale)

          visit admin_runners_path
        end

        it 'has all necessary texts' do
          expect(page).to have_text "#{s_('Runners|All')} 3"
          expect(page).to have_text "#{s_('Runners|Online')} 1"
          expect(page).to have_text "#{s_('Runners|Offline')} 2"
          expect(page).to have_text "#{s_('Runners|Stale')} 1"
        end

        it_behaves_like 'deletes runners in bulk' do
          let(:runner_count) { '3' }
        end
      end

      it 'shows a job count' do
        runner = create(:ci_runner, :project, projects: [project])
        create_list(:ci_build, 2, runner: runner)

        visit admin_runners_path

        within_runner_row(runner.id) do
          expect(find_by_testid('job-count')).to have_content '2'
        end
      end

      it 'shows an Active status badge that links to jobs tab' do
        runner = create(:ci_runner, :project, projects: [project])
        job = create(:ci_build, :running, runner: runner)

        visit admin_runners_path

        within_runner_row(runner.id) do
          click_on(s_('Runners|Active'))
        end

        expect(current_url).to match(admin_runner_path(runner))

        expect(find_by_testid('td-status')).to have_content "Running"
        expect(find_by_testid('td-job')).to have_content "##{job.id}"
      end

      describe 'search' do
        before_all do
          create(:ci_runner, :instance, description: 'runner foo')
          create(:ci_runner, :instance, description: 'runner bar')
        end

        before do
          visit admin_runners_path
        end

        it 'runner types tabs have total counts and can be selected' do
          expect(page).to have_link('All 2')
          expect(page).to have_link('Instance 2')
          expect(page).to have_link('Group 0')
          expect(page).to have_link('Project 0')
        end

        it 'shows runners' do
          expect(page).to have_content("runner foo")
          expect(page).to have_content("runner bar")
        end

        it 'shows correct runner when description matches' do
          input_filtered_search_keys('runner foo')

          expect(page).to have_link('All 1')
          expect(page).to have_link('Instance 1')

          expect(page).to have_content("runner foo")
          expect(page).not_to have_content("runner bar")
        end

        context 'when description does not match' do
          before do
            input_filtered_search_keys('runner baz')
          end

          it_behaves_like 'shows no runners found'

          it 'shows no runner' do
            expect(page).to have_link('All 0')
            expect(page).to have_link('Instance 0')
          end
        end
      end

      describe 'filter by paused' do
        before_all do
          create(:ci_runner, :instance, description: 'runner-active')
          create(:ci_runner, :instance, description: 'runner-paused', active: false)
        end

        before do
          visit admin_runners_path
        end

        it 'shows all runners' do
          expect(page).to have_link('All 2')

          expect(page).to have_content 'runner-active'
          expect(page).to have_content 'runner-paused'
        end

        it 'shows paused runners' do
          input_filtered_search_filter_is_only(s_('Runners|Paused'), 'Yes')

          expect(page).to have_link('All 1')

          expect(page).not_to have_content 'runner-active'
          expect(page).to have_content 'runner-paused'
        end

        it 'shows active runners' do
          input_filtered_search_filter_is_only(s_('Runners|Paused'), 'No')

          expect(page).to have_link('All 1')

          expect(page).to have_content 'runner-active'
          expect(page).not_to have_content 'runner-paused'
        end
      end

      describe 'filter by version prefix' do
        before_all do
          runner_v15 = create(:ci_runner, :instance, description: 'runner-v15')
          runner_v14 = create(:ci_runner, :instance, description: 'runner-v14')

          create(:ci_runner_machine, runner: runner_v15, version: '15.0.0')
          create(:ci_runner_machine, runner: runner_v14, version: '14.0.0')
        end

        before do
          visit admin_runners_path
        end

        it 'shows all runners' do
          expect(page).to have_link('All 2')

          expect(page).to have_content 'runner-v15'
          expect(page).to have_content 'runner-v14'
        end

        it 'shows filtered runner based on supplied prefix' do
          input_filtered_search_filter_is_only(s_('Runners|Version starts with'), '15.0')

          expect(page).to have_link('All 1')

          expect(page).not_to have_content 'runner-v14'
          expect(page).to have_content 'runner-v15'
        end
      end

      describe 'filter by creator' do
        before_all do
          create(:ci_runner, :instance, description: 'runner-creator-admin', creator: admin)
          create(:ci_runner, :instance, description: 'runner-creator-user', creator: user)
        end

        before do
          visit admin_runners_path
        end

        it 'shows all runners' do
          expect(page).to have_link('All 2')

          expect(page).to have_content 'runner-creator-admin'
          expect(page).to have_content 'runner-creator-user'
        end

        it 'shows filtered runner based on creator' do
          input_filtered_search_filter_is_only(s_('Runners|Creator'), admin.username)

          expect(page).to have_link('All 1')

          expect(page).to have_content 'runner-creator-admin'
          expect(page).not_to have_content 'runner-creator-user'
        end

        it 'shows filtered search suggestions' do
          open_filtered_search_suggestions(s_('Runners|Creator'))
          page.within(search_bar_selector) do
            expect(page).to have_content admin.username
            expect(page).to have_content user.username
          end
        end
      end

      describe 'filter by status' do
        let_it_be(:never_contacted) do
          create(:ci_runner, :instance, :unregistered, description: 'runner-never-contacted')
        end

        before_all do
          create(:ci_runner, :instance, :online, description: 'runner-1')
          create(:ci_runner, :instance, :online, description: 'runner-2')
          create(:ci_runner, :instance, :contacted_within_stale_deadline, description: 'runner-offline')
        end

        before do
          visit admin_runners_path
        end

        it 'shows all runners' do
          expect(page).to have_link('All 4')

          expect(page).to have_content 'runner-1'
          expect(page).to have_content 'runner-2'
          expect(page).to have_content 'runner-offline'
          expect(page).to have_content 'runner-never-contacted'
        end

        it 'shows correct runner when status matches' do
          input_filtered_search_filter_is_only('Status', s_('Runners|Online'))

          expect(page).to have_link('All 2')

          expect(page).to have_content 'runner-1'
          expect(page).to have_content 'runner-2'
          expect(page).not_to have_content 'runner-offline'
          expect(page).not_to have_content 'runner-never-contacted'
        end

        it 'shows correct runner when status is selected and search term is entered' do
          input_filtered_search_filter_is_only('Status', s_('Runners|Online'))
          input_filtered_search_keys('runner-1')

          expect(page).to have_link('All 1')

          expect(page).to have_content 'runner-1'
          expect(page).not_to have_content 'runner-2'
          expect(page).not_to have_content 'runner-offline'
          expect(page).not_to have_content 'runner-never-contacted'
        end

        it 'shows correct runner when status filter is entered' do
          # use the string "Never" to avoid using space and trigger an early selection
          input_filtered_search_filter_is_only('Status', 'Never')

          expect(page).to have_link('All 1')

          expect(page).not_to have_content 'runner-1'
          expect(page).not_to have_content 'runner-2'
          expect(page).not_to have_content 'runner-paused'
          expect(page).to have_content 'runner-never-contacted'

          within_runner_row(never_contacted.id) do
            expect(page).to have_selector '.badge', text: s_('Runners|Never contacted')
          end
        end

        context 'when status does not match' do
          before do
            input_filtered_search_filter_is_only('Status', 'Stale')
          end

          it_behaves_like 'shows no runners found'

          it 'shows no runner' do
            expect(page).to have_link('All 0')
          end
        end
      end

      describe 'filter by type' do
        before_all do
          create(:ci_runner, :project, description: 'runner-project', projects: [project])
          create(:ci_runner, :group, description: 'runner-group', groups: [group])
        end

        it '"All" tab is selected by default' do
          visit admin_runners_path

          expect(page).to have_link('All 2')
          expect(page).to have_link('Group 1')
          expect(page).to have_link('Project 1')

          within_testid('runner-type-tabs') do
            expect(page).to have_link('All', class: 'active')
          end
        end

        it 'shows correct runner when type matches' do
          visit admin_runners_path

          expect(page).to have_content 'runner-project'
          expect(page).to have_content 'runner-group'

          within_testid('runner-type-tabs') do
            click_on('Project')

            expect(page).to have_link('Project', class: 'active')
          end

          expect(page).to have_content 'runner-project'
          expect(page).not_to have_content 'runner-group'
        end

        it 'show the same counts after selecting another tab' do
          visit admin_runners_path

          within_testid('runner-type-tabs') do
            click_on('Project')

            expect(page).to have_link('All 2')
            expect(page).to have_link('Group 1')
            expect(page).to have_link('Project 1')
          end
        end

        it 'shows correct runner when type is selected and search term is entered' do
          create(:ci_runner, :project, description: 'runner-2-project', projects: [project])

          visit admin_runners_path

          within_testid('runner-type-tabs') do
            click_on 'Project'
          end

          expect(page).to have_content 'runner-project'
          expect(page).to have_content 'runner-2-project'
          expect(page).not_to have_content 'runner-group'

          input_filtered_search_keys('runner-project')

          expect(page).to have_content 'runner-project'
          expect(page).not_to have_content 'runner-2-project'
          expect(page).not_to have_content 'runner-group'
        end

        it 'maintains the same filter when switching between runner types' do
          create(:ci_runner, :project, description: 'runner-paused-project', active: false, projects: [project])

          visit admin_runners_path

          input_filtered_search_filter_is_only(s_('Runners|Paused'), 'No')

          expect(page).to have_content 'runner-project'
          expect(page).to have_content 'runner-group'
          expect(page).not_to have_content 'runner-paused-project'

          within_testid('runner-type-tabs') do
            click_on 'Project'
          end

          expect(page).to have_content 'runner-project'
          expect(page).not_to have_content 'runner-group'
          expect(page).not_to have_content 'runner-paused-project'
        end

        context 'when type does not match' do
          before do
            visit admin_runners_path
            within_testid('runner-type-tabs') do
              click_on 'Instance'
            end
          end

          it_behaves_like 'shows no runners found'

          it 'shows active tab' do
            expect(page).to have_link('Instance', class: 'active')
          end
        end
      end

      describe 'filter by tag' do
        let_it_be(:runner_1) { create(:ci_runner, :instance, description: 'runner-blue', tag_list: ['blue']) }
        let_it_be(:runner_2) { create(:ci_runner, :instance, description: 'runner-2-blue', tag_list: ['blue']) }
        let_it_be(:runner_3) { create(:ci_runner, :instance, description: 'runner-red', tag_list: ['red']) }

        before do
          visit admin_runners_path
        end

        it 'shows tags suggestions' do
          open_filtered_search_suggestions('Tags')

          page.within(search_bar_selector) do
            expect(page).to have_content 'blue'
            expect(page).to have_content 'red'
          end
        end

        it_behaves_like 'filters by tag' do
          let(:tag) { 'blue' }
          let(:found_runner) { runner_1.description }
          let(:missing_runner) { runner_3.description }
        end

        context 'when tag does not match' do
          before do
            input_filtered_search_filter_is_only('Tags', 'green')
          end

          it_behaves_like 'shows no runners found'
        end

        it 'shows correct runner when tag is selected and search term is entered' do
          input_filtered_search_filter_is_only('Tags', 'blue')

          expect(page).to have_content 'runner-blue'
          expect(page).to have_content 'runner-2-blue'
          expect(page).not_to have_content 'runner-red'

          input_filtered_search_keys('runner-2-blue')

          expect(page).to have_content 'runner-2-blue'
          expect(page).not_to have_content 'runner-blue'
          expect(page).not_to have_content 'runner-red'
        end
      end

      it 'sorts by last contact date' do
        create(:ci_runner, :instance, description: 'runner-1', contacted_at: '2018-07-12')
        create(:ci_runner, :instance, description: 'runner-2', contacted_at: '2018-07-13')

        visit admin_runners_path

        within_testid('runner-list') do
          within('tbody tr:nth-child(1)') do
            expect(page).to have_content 'runner-2'
          end

          within('tbody tr:nth-child(2)') do
            expect(page).to have_content 'runner-1'
          end
        end

        pajamas_sort_by 'Last contact', from: 'Created date'
        click_on 'Sort direction: Descending'

        within_testid('runner-list') do
          within('tbody tr:nth-child(1)') do
            expect(page).to have_content 'runner-1'
          end

          within('tbody tr:nth-child(2)') do
            expect(page).to have_content 'runner-2'
          end
        end
      end
    end

    context "when there are no runners" do
      before do
        visit admin_runners_path
      end

      it_behaves_like 'shows no runners registered'

      it 'shows tabs with total counts equal to 0' do
        aggregate_failures do
          expect(page).to have_link('All 0')
          expect(page).to have_link('Instance 0')
          expect(page).to have_link('Group 0')
          expect(page).to have_link('Project 0')
        end
      end
    end

    context "when visiting outdated URLs" do
      it 'updates ACTIVE runner status to paused=false' do
        visit admin_runners_path('status[]': 'ACTIVE')

        expect(page).to have_current_path(admin_runners_path('paused[]': 'false'))
      end

      it 'updates PAUSED runner status to paused=true' do
        visit admin_runners_path('status[]': 'PAUSED')

        expect(page).to have_current_path(admin_runners_path('paused[]': 'true'))
      end
    end
  end

  describe "Runner create page", :js do
    before do
      visit new_admin_runner_path
    end

    it_behaves_like 'creates runner and shows register page' do
      let(:register_path_pattern) { register_admin_runner_path('.*') }
    end
  end

  describe "Runner show page", :js do
    let_it_be(:runner) { create(:ci_runner, description: 'runner-foo', tag_list: ['tag1']) }
    let_it_be(:runner_job) { create(:ci_build, runner: runner) }

    before do
      visit admin_runner_path(runner)
    end

    describe 'runner show page breadcrumbs' do
      it 'contains the current runner id and token' do
        within_testid('breadcrumb-links') do
          expect(find('li:last-of-type')).to have_link("##{runner.id} (#{runner.short_sha})")
        end
      end
    end

    it 'shows runner details' do
      aggregate_failures do
        expect(page).to have_content 'Description runner-foo'
        expect(page).to have_content 'Last contact Never contacted'
        expect(page).to have_content 'Configuration Runs untagged jobs'
        expect(page).to have_content 'Maximum job timeout None'
        expect(page).to have_content 'Tags tag1'
      end
    end

    it_behaves_like 'shows runner jobs tab' do
      let(:job_count) { '1' }
      let(:job) { runner_job }
    end

    describe 'when a runner is deleted' do
      before do
        click_on 'Delete runner'

        within_modal do
          click_on 'Permanently delete runner'
        end
      end

      it 'deletes runner and redirects to runner list' do
        expect(find_by_testid('alert-success')).to have_content('deleted')
        expect(current_url).to match(admin_runners_path)
      end
    end
  end

  describe "Runner edit page", :js do
    let_it_be(:project1) { create(:project) }
    let_it_be(:project2) { create(:project, organization: project1.organization) }
    let_it_be(:project_runner) { create(:ci_runner, :unregistered, :project) }

    before do
      visit edit_admin_runner_path(project_runner)
    end

    it_behaves_like 'submits edit runner form' do
      let(:runner) { project_runner }
      let(:runner_page_path) { admin_runner_path(project_runner) }
    end

    it_behaves_like 'shows locked field'

    describe 'breadcrumbs' do
      it 'contains the current runner id and token' do
        within_testid('breadcrumb-links') do
          expect(page).to have_link("##{project_runner.id} (#{project_runner.short_sha})")
          expect(find('li:last-of-type')).to have_content("Edit")
        end
      end
    end

    describe 'runner header', :js do
      it 'contains the runner status, type and id' do
        expect(page).to have_content(
          "##{project_runner.id} (#{project_runner.short_sha}) #{s_('Runners|Never contacted')} Project Created"
        )
      end
    end

    context 'when a runner is updated', :js do
      before do
        click_on _('Save changes')
      end

      it 'show success alert and redirects to runner page' do
        expect(current_url).to match(admin_runner_path(project_runner))
        expect(find_by_testid('alert-success')).to have_content('saved')
      end
    end

    describe 'projects' do
      it 'contains project names' do
        expect(page).to have_content(project1.full_name)
        expect(page).to have_content(project2.full_name)
      end
    end

    describe 'search' do
      before do
        search_form = find('#runner-projects-search')
        search_form.fill_in 'search', with: project1.name
        search_form.click_button 'Search'
      end

      it 'contains name of correct project' do
        expect(page).to have_content(project1.full_name)
        expect(page).not_to have_content(project2.full_name)
      end
    end

    describe 'enable/create' do
      shared_examples 'assignable runner' do
        it 'enables a runner for a project' do
          within_testid('unassigned-projects') do
            within('tr', text: project2.full_name) do
              click_on 'Enable'
            end
          end

          assigned_project = find_by_testid('assigned-projects')

          expect(page).to have_content('Runner assigned to project.')
          expect(assigned_project).to have_content(project2.name)
        end
      end

      context 'with project runner' do
        let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project1]) }

        before do
          visit edit_admin_runner_path(project_runner)
        end

        it_behaves_like 'assignable runner'
      end

      context 'with locked runner' do
        let_it_be(:locked_runner) { create(:ci_runner, :project, projects: [project1], locked: true) }

        before do
          visit edit_admin_runner_path(locked_runner)
        end

        it_behaves_like 'assignable runner'
      end
    end

    describe 'disable/destroy' do
      let_it_be(:runner) { create(:ci_runner, :project, projects: [project1]) }

      before do
        visit edit_admin_runner_path(runner)
      end

      it 'removed project runner from project' do
        within_testid('assigned-projects') do
          click_on 'Disable'
        end

        new_runner_project = find_by_testid('unassigned-projects')

        expect(page).to have_content('Runner unassigned from project.')
        expect(new_runner_project).to have_content(project1.name)
      end
    end
  end
end
