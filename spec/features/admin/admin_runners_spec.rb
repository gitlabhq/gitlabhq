# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin Runners" do
  include StubENV
  include Spec::Support::Helpers::ModalHelpers

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    admin = create(:admin)
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)

    wait_for_requests
  end

  describe "Runners page", :js do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:project) { create(:project, namespace: namespace, creator: user) }

    context "when there are runners" do
      it 'has all necessary texts' do
        create(:ci_runner, :instance, created_at: 1.year.ago, contacted_at: Time.now)
        create(:ci_runner, :instance, created_at: 1.year.ago, contacted_at: 1.week.ago)
        create(:ci_runner, :instance, created_at: 1.year.ago, contacted_at: 1.year.ago)

        visit admin_runners_path

        expect(page).to have_text "Register an instance runner"
        expect(page).to have_text "Online runners 1"
        expect(page).to have_text "Offline runners 2"
        expect(page).to have_text "Stale runners 1"
      end

      it 'with an instance runner shows an instance badge' do
        runner = create(:ci_runner, :instance)

        visit admin_runners_path

        within "[data-testid='runner-row-#{runner.id}']" do
          expect(page).to have_selector '.badge', text: 'shared'
        end
      end

      it 'with a group runner shows a group badge' do
        runner = create(:ci_runner, :group, groups: [group])

        visit admin_runners_path

        within "[data-testid='runner-row-#{runner.id}']" do
          expect(page).to have_selector '.badge', text: 'group'
        end
      end

      it 'with a project runner shows a project badge' do
        runner = create(:ci_runner, :project, projects: [project])

        visit admin_runners_path

        within "[data-testid='runner-row-#{runner.id}']" do
          expect(page).to have_selector '.badge', text: 'specific'
        end
      end

      it 'shows a job count' do
        runner = create(:ci_runner, :project, projects: [project])

        create(:ci_build, runner: runner)
        create(:ci_build, runner: runner)

        visit admin_runners_path

        within "[data-testid='runner-row-#{runner.id}'] [data-label='Jobs']" do
          expect(page).to have_content '2'
        end
      end

      describe 'delete runner' do
        let!(:runner) { create(:ci_runner, description: 'runner-foo') }

        before do
          visit admin_runners_path

          within "[data-testid='runner-row-#{runner.id}']" do
            click_on 'Delete runner'
          end
        end

        it 'shows a confirmation modal' do
          expect(page).to have_text "Delete runner ##{runner.id} (#{runner.short_sha})?"
          expect(page).to have_text "Are you sure you want to continue?"
        end

        it 'deletes a runner' do
          within '.modal' do
            click_on 'Delete runner'
          end

          expect(page.find('.gl-toast')).to have_text(/Runner .+ deleted/)
          expect(page).not_to have_content 'runner-foo'
        end

        it 'cancels runner deletion' do
          within '.modal' do
            click_on 'Cancel'
          end

          wait_for_requests

          expect(page).to have_content 'runner-foo'
        end
      end

      describe 'search' do
        before do
          create(:ci_runner, :instance, description: 'runner-foo')
          create(:ci_runner, :instance, description: 'runner-bar')

          visit admin_runners_path
        end

        it 'runner types tabs have total counts and can be selected' do
          expect(page).to have_link('All 2')
          expect(page).to have_link('Instance 2')
          expect(page).to have_link('Group 0')
          expect(page).to have_link('Project 0')
        end

        it 'shows runners' do
          expect(page).to have_content("runner-foo")
          expect(page).to have_content("runner-bar")
        end

        it 'shows correct runner when description matches' do
          input_filtered_search_keys('runner-foo')

          expect(page).to have_link('All 1')
          expect(page).to have_link('Instance 1')

          expect(page).to have_content("runner-foo")
          expect(page).not_to have_content("runner-bar")
        end

        it 'shows no runner when description does not match' do
          input_filtered_search_keys('runner-baz')

          expect(page).to have_link('All 0')
          expect(page).to have_link('Instance 0')

          expect(page).to have_text 'No runners found'
        end
      end

      describe 'filter by status' do
        let!(:never_contacted) { create(:ci_runner, :instance, description: 'runner-never-contacted', contacted_at: nil) }

        before do
          create(:ci_runner, :instance, description: 'runner-1', contacted_at: Time.now)
          create(:ci_runner, :instance, description: 'runner-2', contacted_at: Time.now)
          create(:ci_runner, :instance, description: 'runner-paused', active: false, contacted_at: Time.now)

          visit admin_runners_path
        end

        it 'shows all runners' do
          expect(page).to have_content 'runner-1'
          expect(page).to have_content 'runner-2'
          expect(page).to have_content 'runner-paused'
          expect(page).to have_content 'runner-never-contacted'

          expect(page).to have_link('All 4')
        end

        it 'shows correct runner when status matches' do
          input_filtered_search_filter_is_only('Status', 'Active')

          expect(page).to have_link('All 3')

          expect(page).to have_content 'runner-1'
          expect(page).to have_content 'runner-2'
          expect(page).to have_content 'runner-never-contacted'
          expect(page).not_to have_content 'runner-paused'
        end

        it 'shows no runner when status does not match' do
          input_filtered_search_filter_is_only('Status', 'Stale')

          expect(page).to have_link('All 0')

          expect(page).to have_text 'No runners found'
        end

        it 'shows correct runner when status is selected and search term is entered' do
          input_filtered_search_filter_is_only('Status', 'Active')
          input_filtered_search_keys('runner-1')

          expect(page).to have_link('All 1')

          expect(page).to have_content 'runner-1'
          expect(page).not_to have_content 'runner-2'
          expect(page).not_to have_content 'runner-never-contacted'
          expect(page).not_to have_content 'runner-paused'
        end

        it 'shows correct runner when status filter is entered' do
          # use the string "Never" to avoid using space and trigger an early selection
          input_filtered_search_filter_is_only('Status', 'Never')

          expect(page).to have_link('All 1')

          expect(page).not_to have_content 'runner-1'
          expect(page).not_to have_content 'runner-2'
          expect(page).not_to have_content 'runner-paused'
          expect(page).to have_content 'runner-never-contacted'

          within "[data-testid='runner-row-#{never_contacted.id}']" do
            expect(page).to have_selector '.badge', text: 'never contacted'
          end
        end
      end

      describe 'filter by type' do
        before do
          create(:ci_runner, :project, description: 'runner-project', projects: [project])
          create(:ci_runner, :group, description: 'runner-group', groups: [group])
        end

        it '"All" tab is selected by default' do
          visit admin_runners_path

          expect(page).to have_link('All 2')
          expect(page).to have_link('Group 1')
          expect(page).to have_link('Project 1')

          page.within('[data-testid="runner-type-tabs"]') do
            expect(page).to have_link('All', class: 'active')
          end
        end

        it 'shows correct runner when type matches' do
          visit admin_runners_path

          expect(page).to have_content 'runner-project'
          expect(page).to have_content 'runner-group'

          page.within('[data-testid="runner-type-tabs"]') do
            click_on('Project')

            expect(page).to have_link('Project', class: 'active')
          end

          expect(page).to have_content 'runner-project'
          expect(page).not_to have_content 'runner-group'
        end

        it 'show the same counts after selecting another tab' do
          visit admin_runners_path

          page.within('[data-testid="runner-type-tabs"]') do
            click_on('Project')

            expect(page).to have_link('All 2')
            expect(page).to have_link('Group 1')
            expect(page).to have_link('Project 1')
          end
        end

        it 'shows no runner when type does not match' do
          visit admin_runners_path

          page.within('[data-testid="runner-type-tabs"]') do
            click_on 'Instance'

            expect(page).to have_link('Instance', class: 'active')
          end

          expect(page).not_to have_content 'runner-project'
          expect(page).not_to have_content 'runner-group'

          expect(page).to have_text 'No runners found'
        end

        it 'shows correct runner when type is selected and search term is entered' do
          create(:ci_runner, :project, description: 'runner-2-project', projects: [project])

          visit admin_runners_path

          page.within('[data-testid="runner-type-tabs"]') do
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

          input_filtered_search_filter_is_only('Status', 'Active')

          expect(page).to have_content 'runner-project'
          expect(page).to have_content 'runner-group'
          expect(page).not_to have_content 'runner-paused-project'

          page.within('[data-testid="runner-type-tabs"]') do
            click_on 'Project'
          end

          expect(page).to have_content 'runner-project'
          expect(page).not_to have_content 'runner-group'
          expect(page).not_to have_content 'runner-paused-project'
        end
      end

      describe 'filter by tag' do
        before do
          create(:ci_runner, :instance, description: 'runner-blue', tag_list: ['blue'])
          create(:ci_runner, :instance, description: 'runner-red', tag_list: ['red'])
        end

        it 'shows correct runner when tag matches' do
          visit admin_runners_path

          expect(page).to have_content 'runner-blue'
          expect(page).to have_content 'runner-red'

          input_filtered_search_filter_is_only('Tags', 'blue')

          expect(page).to have_content 'runner-blue'
          expect(page).not_to have_content 'runner-red'
        end

        it 'shows no runner when tag does not match' do
          visit admin_runners_path

          input_filtered_search_filter_is_only('Tags', 'green')

          expect(page).not_to have_content 'runner-blue'
          expect(page).to have_text 'No runners found'
        end

        it 'shows correct runner when tag is selected and search term is entered' do
          create(:ci_runner, :instance, description: 'runner-2-blue', tag_list: ['blue'])

          visit admin_runners_path

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
        create(:ci_runner, :instance, description: 'runner-1', created_at: '2018-07-12 15:37', contacted_at: '2018-07-12 15:37')
        create(:ci_runner, :instance, description: 'runner-2', created_at: '2018-07-12 16:37', contacted_at: '2018-07-12 16:37')

        visit admin_runners_path

        within '[data-testid="runner-list"] tbody tr:nth-child(1)' do
          expect(page).to have_content 'runner-2'
        end

        within '[data-testid="runner-list"] tbody tr:nth-child(2)' do
          expect(page).to have_content 'runner-1'
        end

        click_on 'Created date' # Open "sort by" dropdown
        click_on 'Last contact'
        click_on 'Sort direction: Descending'

        within '[data-testid="runner-list"] tbody tr:nth-child(1)' do
          expect(page).to have_content 'runner-1'
        end

        within '[data-testid="runner-list"] tbody tr:nth-child(2)' do
          expect(page).to have_content 'runner-2'
        end
      end
    end

    context "when there are no runners" do
      before do
        visit admin_runners_path
      end

      it 'has all necessary texts including no runner message' do
        expect(page).to have_text "Register an instance runner"

        expect(page).to have_text "Online runners 0"
        expect(page).to have_text "Offline runners 0"
        expect(page).to have_text "Stale runners 0"

        expect(page).to have_text 'No runners found'
      end

      it 'shows tabs with total counts equal to 0' do
        expect(page).to have_link('All 0')
        expect(page).to have_link('Instance 0')
        expect(page).to have_link('Group 0')
        expect(page).to have_link('Project 0')
      end
    end

    context "when visiting outdated URLs" do
      it 'updates NOT_CONNECTED runner status to NEVER_CONNECTED' do
        visit admin_runners_path('status[]': 'NOT_CONNECTED')

        expect(page).to have_current_path(admin_runners_path('status[]': 'NEVER_CONTACTED') )
      end
    end

    describe 'runners registration' do
      let!(:token) { Gitlab::CurrentSettings.runners_registration_token }

      before do
        visit admin_runners_path

        click_on 'Register an instance runner'
      end

      describe 'show registration instructions' do
        before do
          click_on 'Show runner installation and registration instructions'

          wait_for_requests
        end

        it 'opens runner installation modal' do
          expect(page).to have_text "Install a runner"

          expect(page).to have_text "Environment"
          expect(page).to have_text "Architecture"
          expect(page).to have_text "Download and install binary"
        end

        it 'dismisses runner installation modal' do
          within_modal do
            click_button('Close', match: :first)
          end

          expect(page).not_to have_text "Install a runner"
        end
      end

      it 'has a registration token' do
        click_on 'Click to reveal'
        expect(page.find('[data-testid="token-value"]')).to have_content(token)
      end

      describe 'reset registration token' do
        let(:page_token) { find('[data-testid="token-value"]').text }

        before do
          click_on 'Reset registration token'

          within_modal do
            click_button('Reset token', match: :first)
          end

          wait_for_requests
        end

        it 'changes registration token' do
          click_on 'Register an instance runner'

          click_on 'Click to reveal'
          expect(page_token).not_to eq token
        end
      end
    end
  end

  describe "Runner show page", :js do
    let(:runner) do
      create(
        :ci_runner,
        description: 'runner-foo',
        version: '14.0',
        ip_address: '127.0.0.1',
        tag_list: ['tag1']
      )
    end

    before do
      visit admin_runner_path(runner)
    end

    describe 'runner show page breadcrumbs' do
      it 'contains the current runner id and token' do
        page.within '[data-testid="breadcrumb-links"]' do
          expect(page.find('h2')).to have_link("##{runner.id} (#{runner.short_sha})")
        end
      end
    end

    it 'shows runner details' do
      aggregate_failures do
        expect(page).to have_content 'Description runner-foo'
        expect(page).to have_content 'Last contact Never contacted'
        expect(page).to have_content 'Version 14.0'
        expect(page).to have_content 'IP Address 127.0.0.1'
        expect(page).to have_content 'Configuration Runs untagged jobs'
        expect(page).to have_content 'Maximum job timeout None'
        expect(page).to have_content 'Tags tag1'
      end
    end
  end

  describe "Runner edit page" do
    let(:runner) { create(:ci_runner) }

    before do
      @project1 = create(:project)
      @project2 = create(:project)
      visit edit_admin_runner_path(runner)

      wait_for_requests
    end

    describe 'runner edit page breadcrumbs' do
      it 'contains the current runner id and token' do
        page.within '[data-testid="breadcrumb-links"]' do
          expect(page).to have_link("##{runner.id} (#{runner.short_sha})")
          expect(page.find('h2')).to have_content("Edit")
        end
      end
    end

    describe 'runner header', :js do
      it 'contains the runner status, type and id' do
        expect(page).to have_content("never contacted shared Runner ##{runner.id} created")
      end
    end

    describe 'projects' do
      it 'contains project names' do
        expect(page).to have_content(@project1.full_name)
        expect(page).to have_content(@project2.full_name)
      end
    end

    describe 'search' do
      before do
        search_form = find('#runner-projects-search')
        search_form.fill_in 'search', with: @project1.name
        search_form.click_button 'Search'
      end

      it 'contains name of correct project' do
        expect(page).to have_content(@project1.full_name)
        expect(page).not_to have_content(@project2.full_name)
      end
    end

    describe 'enable/create' do
      shared_examples 'assignable runner' do
        it 'enables a runner for a project' do
          within '[data-testid="unassigned-projects"]' do
            click_on 'Enable'
          end

          assigned_project = page.find('[data-testid="assigned-projects"]')

          expect(page).to have_content('Runner assigned to project.')
          expect(assigned_project).to have_content(@project2.path)
        end
      end

      context 'with specific runner' do
        let(:runner) { create(:ci_runner, :project, projects: [@project1]) }

        before do
          visit edit_admin_runner_path(runner)
        end

        it_behaves_like 'assignable runner'
      end

      context 'with locked runner' do
        let(:runner) { create(:ci_runner, :project, projects: [@project1], locked: true) }

        before do
          visit edit_admin_runner_path(runner)
        end

        it_behaves_like 'assignable runner'
      end

      context 'with shared runner' do
        let(:runner) { create(:ci_runner, :instance) }

        before do
          @project1.destroy!
          visit edit_admin_runner_path(runner)
        end

        it_behaves_like 'assignable runner'
      end
    end

    describe 'disable/destroy' do
      let(:runner) { create(:ci_runner, :project, projects: [@project1]) }

      before do
        visit edit_admin_runner_path(runner)
      end

      it 'removed specific runner from project' do
        within '[data-testid="assigned-projects"]' do
          click_on 'Disable'
        end

        new_runner_project = page.find('[data-testid="unassigned-projects"]')

        expect(page).to have_content('Runner unassigned from project.')
        expect(new_runner_project).to have_content(@project1.path)
      end
    end
  end

  private

  def search_bar_selector
    '[data-testid="runners-filtered-search"]'
  end

  # The filters must be clicked first to be able to receive events
  # See: https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1493
  def focus_filtered_search
    page.within(search_bar_selector) do
      page.find('.gl-filtered-search-term-token').click
    end
  end

  def input_filtered_search_keys(search_term)
    focus_filtered_search

    page.within(search_bar_selector) do
      page.find('input').send_keys(search_term)
      click_on 'Search'
    end

    wait_for_requests
  end

  def input_filtered_search_filter_is_only(filter, value)
    focus_filtered_search

    page.within(search_bar_selector) do
      click_on filter

      # For OPERATOR_IS_ONLY, clicking the filter
      # immediately preselects "=" operator

      page.find('input').send_keys(value)
      page.find('input').send_keys(:enter)

      click_on 'Search'
    end

    wait_for_requests
  end
end
