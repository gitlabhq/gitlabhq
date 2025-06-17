# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin manages runners in admin runner list", :freeze_time, :js, feature_category: :fleet_visibility do
  include Features::SortingHelpers
  include Features::RunnersHelpers
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:admin) { create(:admin) }

  before do
    sign_in(admin)
    enable_admin_mode!(admin)
  end

  context "with runners" do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:project) { create(:project, namespace: namespace, creator: user) }

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
          expect(page).to have_selector '.badge', text: 'Instance'
        end
      end
    end

    context "with multiple runners" do
      before do
        create(:ci_runner, :instance, :almost_offline)
        create(:ci_runner, :instance, :offline)
        create(:ci_runner, :instance, :stale)

        visit admin_runners_path
      end

      it 'has all necessary texts' do
        expect(page).to have_text "All 3"
        expect(page).to have_text "Online 1"
        expect(page).to have_text "Offline 2"
        expect(page).to have_text "Stale 1"
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
        click_on('Active')
      end

      expect(current_url).to match(admin_runner_path(runner))

      expect(find_by_testid('td-status')).to have_content "Running"
      expect(find_by_testid('td-job')).to have_content "##{job.id}"
    end

    describe 'searches for a runner' do
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
        create(:ci_runner, :instance, :paused, description: 'runner-paused')
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
        input_filtered_search_filter_is_only('Paused', 'Yes')

        expect(page).to have_link('All 1')

        expect(page).not_to have_content 'runner-active'
        expect(page).to have_content 'runner-paused'
      end

      it 'shows active runners' do
        input_filtered_search_filter_is_only('Paused', 'No')

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
        input_filtered_search_filter_is_only('Version starts with', '15.0')

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
        input_filtered_search_filter_is_only('Creator', admin.username)

        expect(page).to have_link('All 1')

        expect(page).to have_content 'runner-creator-admin'
        expect(page).not_to have_content 'runner-creator-user'
      end

      it 'shows filtered search suggestions' do
        open_filtered_search_suggestions('Creator')
        page.within(search_bar_selector) do
          expect(page).to have_content admin.username
          expect(page).to have_content user.username
        end
      end
    end

    describe 'filter by status' do
      before_all do
        freeze_time # Freeze time before `let_it_be` runs, so that runner statuses are frozen during execution

        create(:ci_runner, :instance, :online, description: 'runner-1')
        create(:ci_runner, :instance, :almost_offline, description: 'runner-2')
        create(:ci_runner, :instance, :contacted_within_stale_deadline, description: 'runner-offline')
      end

      after :all do
        unfreeze_time
      end

      let_it_be(:never_contacted) do
        create(:ci_runner, :instance, :unregistered, description: 'runner-never-contacted')
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
        input_filtered_search_filter_is_only('Status', 'Online')

        expect(page).to have_link('All 2')

        expect(page).to have_content 'runner-1'
        expect(page).to have_content 'runner-2'
        expect(page).not_to have_content 'runner-offline'
        expect(page).not_to have_content 'runner-never-contacted'
      end

      it 'shows correct runner when status is selected and search term is entered' do
        input_filtered_search_filter_is_only('Status', 'Online')
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
          expect(page).to have_selector '.badge', text: 'Never contacted'
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
        create(:ci_runner, :project, :paused, description: 'runner-paused-project', projects: [project])

        visit admin_runners_path

        input_filtered_search_filter_is_only('Paused', 'No')

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

  context "with no runners" do
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
