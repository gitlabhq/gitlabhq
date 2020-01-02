# frozen_string_literal: true

require 'spec_helper'

describe "Admin Runners" do
  include StubENV
  include FilteredSearchHelpers
  include SortingHelper

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(create(:admin))
  end

  describe "Runners page" do
    let(:pipeline) { create(:ci_pipeline) }

    context "when there are runners" do
      it 'has all necessary texts' do
        runner = create(:ci_runner, contacted_at: Time.now)
        create(:ci_build, pipeline: pipeline, runner_id: runner.id)
        visit admin_runners_path

        expect(page).to have_text "Set up a shared Runner manually"
        expect(page).to have_text "Runners currently online: 1"
      end

      describe 'search', :js do
        before do
          create(:ci_runner, description: 'runner-foo')
          create(:ci_runner, description: 'runner-bar')

          visit admin_runners_path
        end

        it 'shows correct runner when description matches' do
          input_filtered_search_keys('runner-foo')

          expect(page).to have_content("runner-foo")
          expect(page).not_to have_content("runner-bar")
        end

        it 'shows no runner when description does not match' do
          input_filtered_search_keys('runner-baz')

          expect(page).to have_text 'No runners found'
        end
      end

      describe 'filter by status', :js do
        it 'shows correct runner when status matches' do
          create(:ci_runner, description: 'runner-active', active: true)
          create(:ci_runner, description: 'runner-paused', active: false)

          visit admin_runners_path

          expect(page).to have_content 'runner-active'
          expect(page).to have_content 'runner-paused'

          input_filtered_search_keys('status=active')
          expect(page).to have_content 'runner-active'
          expect(page).not_to have_content 'runner-paused'
        end

        it 'shows no runner when status does not match' do
          create(:ci_runner, :online, description: 'runner-active', active: true)
          create(:ci_runner, :online, description: 'runner-paused', active: false)

          visit admin_runners_path

          input_filtered_search_keys('status=offline')

          expect(page).not_to have_content 'runner-active'
          expect(page).not_to have_content 'runner-paused'

          expect(page).to have_text 'No runners found'
        end

        it 'shows correct runner when status is selected and search term is entered' do
          create(:ci_runner, description: 'runner-a-1', active: true)
          create(:ci_runner, description: 'runner-a-2', active: false)
          create(:ci_runner, description: 'runner-b-1', active: true)

          visit admin_runners_path

          input_filtered_search_keys('status=active')
          expect(page).to have_content 'runner-a-1'
          expect(page).to have_content 'runner-b-1'
          expect(page).not_to have_content 'runner-a-2'

          input_filtered_search_keys('status=active runner-a')
          expect(page).to have_content 'runner-a-1'
          expect(page).not_to have_content 'runner-b-1'
          expect(page).not_to have_content 'runner-a-2'
        end
      end

      describe 'filter by type', :js do
        it 'shows correct runner when type matches' do
          create :ci_runner, :project, description: 'runner-project'
          create :ci_runner, :group, description: 'runner-group'

          visit admin_runners_path

          expect(page).to have_content 'runner-project'
          expect(page).to have_content 'runner-group'

          input_filtered_search_keys('type=project_type')
          expect(page).to have_content 'runner-project'
          expect(page).not_to have_content 'runner-group'
        end

        it 'shows no runner when type does not match' do
          create :ci_runner, :project, description: 'runner-project'
          create :ci_runner, :group, description: 'runner-group'

          visit admin_runners_path

          input_filtered_search_keys('type=instance_type')

          expect(page).not_to have_content 'runner-project'
          expect(page).not_to have_content 'runner-group'

          expect(page).to have_text 'No runners found'
        end

        it 'shows correct runner when type is selected and search term is entered' do
          create :ci_runner, :project, description: 'runner-a-1'
          create :ci_runner, :instance, description: 'runner-a-2'
          create :ci_runner, :project, description: 'runner-b-1'

          visit admin_runners_path

          input_filtered_search_keys('type=project_type')
          expect(page).to have_content 'runner-a-1'
          expect(page).to have_content 'runner-b-1'
          expect(page).not_to have_content 'runner-a-2'

          input_filtered_search_keys('type=project_type runner-a')
          expect(page).to have_content 'runner-a-1'
          expect(page).not_to have_content 'runner-b-1'
          expect(page).not_to have_content 'runner-a-2'
        end
      end

      describe 'filter by tag', :js do
        it 'shows correct runner when tag matches' do
          create :ci_runner, description: 'runner-blue', tag_list: ['blue']
          create :ci_runner, description: 'runner-red', tag_list: ['red']

          visit admin_runners_path

          expect(page).to have_content 'runner-blue'
          expect(page).to have_content 'runner-red'

          input_filtered_search_keys('tag=blue')

          expect(page).to have_content 'runner-blue'
          expect(page).not_to have_content 'runner-red'
        end

        it 'shows no runner when tag does not match' do
          create :ci_runner, description: 'runner-blue', tag_list: ['blue']
          create :ci_runner, description: 'runner-red', tag_list: ['blue']

          visit admin_runners_path

          input_filtered_search_keys('tag=red')

          expect(page).not_to have_content 'runner-blue'
          expect(page).not_to have_content 'runner-blue'
          expect(page).to have_text 'No runners found'
        end

        it 'shows correct runner when tag is selected and search term is entered' do
          create :ci_runner, description: 'runner-a-1', tag_list: ['blue']
          create :ci_runner, description: 'runner-a-2', tag_list: ['red']
          create :ci_runner, description: 'runner-b-1', tag_list: ['blue']

          visit admin_runners_path

          input_filtered_search_keys('tag=blue')

          expect(page).to have_content 'runner-a-1'
          expect(page).to have_content 'runner-b-1'
          expect(page).not_to have_content 'runner-a-2'

          input_filtered_search_keys('tag=blue runner-a')

          expect(page).to have_content 'runner-a-1'
          expect(page).not_to have_content 'runner-b-1'
          expect(page).not_to have_content 'runner-a-2'
        end
      end

      it 'sorts by last contact date', :js do
        create(:ci_runner, description: 'runner-1', created_at: '2018-07-12 15:37', contacted_at: '2018-07-12 15:37')
        create(:ci_runner, description: 'runner-2', created_at: '2018-07-12 16:37', contacted_at: '2018-07-12 16:37')

        visit admin_runners_path

        within '.runners-content .gl-responsive-table-row:nth-child(2)' do
          expect(page).to have_content 'runner-2'
        end

        within '.runners-content .gl-responsive-table-row:nth-child(3)' do
          expect(page).to have_content 'runner-1'
        end

        sorting_by 'Last Contact'

        within '.runners-content .gl-responsive-table-row:nth-child(2)' do
          expect(page).to have_content 'runner-1'
        end

        within '.runners-content .gl-responsive-table-row:nth-child(3)' do
          expect(page).to have_content 'runner-2'
        end
      end
    end

    context "when there are no runners" do
      before do
        visit admin_runners_path
      end

      it 'has all necessary texts including no runner message' do
        expect(page).to have_text "Set up a shared Runner manually"
        expect(page).to have_text "Runners currently online: 0"
        expect(page).to have_text 'No runners found'
      end
    end

    context 'group runner' do
      let(:group) { create(:group) }
      let!(:runner) { create(:ci_runner, :group, groups: [group]) }

      it 'shows the label and does not show the project count' do
        visit admin_runners_path

        within "#runner_#{runner.id}" do
          expect(page).to have_selector '.badge', text: 'group'
          expect(page).to have_text 'n/a'
        end
      end
    end

    context 'shared runner' do
      it 'shows the label and does not show the project count' do
        runner = create(:ci_runner, :instance)

        visit admin_runners_path

        within "#runner_#{runner.id}" do
          expect(page).to have_selector '.badge', text: 'shared'
          expect(page).to have_text 'n/a'
        end
      end
    end

    context 'specific runner' do
      it 'shows the label and the project count' do
        project = create(:project)
        runner = create(:ci_runner, :project, projects: [project])

        visit admin_runners_path

        within "#runner_#{runner.id}" do
          expect(page).to have_selector '.badge', text: 'specific'
          expect(page).to have_text '1'
        end
      end
    end
  end

  describe "Runner show page" do
    let(:runner) { create(:ci_runner) }

    before do
      @project1 = create(:project)
      @project2 = create(:project)
      visit admin_runner_path(runner)
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
          within '.unassigned-projects' do
            click_on 'Enable'
          end

          assigned_project = page.find('.assigned-projects')

          expect(assigned_project).to have_content(@project2.path)
        end
      end

      context 'with specific runner' do
        let(:runner) { create(:ci_runner, :project, projects: [@project1]) }

        before do
          visit admin_runner_path(runner)
        end

        it_behaves_like 'assignable runner'
      end

      context 'with locked runner' do
        let(:runner) { create(:ci_runner, :project, projects: [@project1], locked: true) }

        before do
          visit admin_runner_path(runner)
        end

        it_behaves_like 'assignable runner'
      end

      context 'with shared runner' do
        let(:runner) { create(:ci_runner, :instance) }

        before do
          @project1.destroy
          visit admin_runner_path(runner)
        end

        it_behaves_like 'assignable runner'
      end
    end

    describe 'disable/destroy' do
      let(:runner) { create(:ci_runner, :project, projects: [@project1]) }

      before do
        visit admin_runner_path(runner)
      end

      it 'enables specific runner for project' do
        within '.assigned-projects' do
          click_on 'Disable'
        end

        new_runner_project = page.find('.unassigned-projects')

        expect(new_runner_project).to have_content(@project1.path)
      end
    end
  end

  describe 'runners registration token' do
    let!(:token) { Gitlab::CurrentSettings.runners_registration_token }

    before do
      visit admin_runners_path
    end

    it 'has a registration token' do
      expect(page.find('#registration_token')).to have_content(token)
    end

    describe 'reload registration token' do
      let(:page_token) { find('#registration_token').text }

      before do
        click_button 'Reset runners registration token'
      end

      it 'changes registration token' do
        expect(page_token).not_to eq token
      end
    end
  end
end
