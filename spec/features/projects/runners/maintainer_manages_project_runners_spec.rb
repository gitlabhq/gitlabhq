# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Maintainer manages project runners', feature_category: :fleet_visibility do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project]) }

  before_all do
    project.add_maintainer(user)
  end

  before do
    sign_in(user)
  end

  context 'when a project_type runner is activated on the project' do
    let_it_be(:project_runner_manager) do
      create(:ci_runner_machine, runner: project_runner, platform: 'darwin')
    end

    it 'user sees the project runner' do
      visit project_runners_path(project)

      within_testid 'assigned_project_runners' do
        expect(page).to have_content(project_runner.display_name)
      end

      click_on project_runner.short_sha

      expect(page).to have_content(project_runner_manager.platform)
    end

    it 'user can pause and resume the project runner' do
      visit project_runners_path(project)

      within_testid 'assigned_project_runners' do
        expect(page).to have_link('Pause')
      end

      click_on 'Pause'

      within_testid 'assigned_project_runners' do
        expect(page).to have_link('Resume')
      end

      click_on 'Resume'

      within_testid 'assigned_project_runners' do
        expect(page).to have_link('Pause')
      end
    end

    it 'user removes an activated project runner if this is last project for that runners' do
      visit project_runners_path(project)

      within_testid 'assigned_project_runners' do
        click_on 'Remove runner'
      end

      expect(page).not_to have_content(project_runner.display_name)
    end

    it 'user edits runner to set it as protected', :js do
      visit project_runners_path(project)

      within_testid 'assigned_project_runners' do
        first('[data-testid="edit-runner-link"]').click
      end

      expect(page.find_field('protected')).not_to be_checked

      check 'protected'
      click_button 'Save changes'

      expect(page).to have_content 'Protected Yes'
    end

    context 'when a runner has a tag', :js do
      before do
        project_runner.update!(tag_list: ['tag'])
      end

      it 'user edits runner to not run untagged jobs' do
        visit project_runners_path(project)

        within_testid 'assigned_project_runners' do
          first('[data-testid="edit-runner-link"]').click
        end

        expect(page.find_field('run-untagged')).to be_checked

        uncheck 'run-untagged'
        click_button 'Save changes'

        expect(page).to have_content 'Can run untagged jobs No'
      end
    end

    context 'when a instance runner is activated on the project' do
      let!(:shared_runner) { create(:ci_runner, :instance) }

      it 'user sees CI/CD setting page' do
        visit project_runners_path(project)

        within_testid 'available-shared-runners' do
          expect(page).to have_content(shared_runner.display_name)
        end
      end

      context 'when multiple instance runners are configured' do
        let_it_be(:shared_runner_2) { create(:ci_runner, :instance) }

        it 'shows the runner count' do
          visit project_runners_path(project)

          within_testid 'available-shared-runners' do
            expect(page).to have_content format(_('Available instance runners: %{count}'), { count: 2 })
          end
        end

        it 'adds pagination to the instance runner list' do
          stub_const('Projects::Settings::CiCdController::NUMBER_OF_RUNNERS_PER_PAGE', 1)

          visit project_runners_path(project)

          within_testid 'available-shared-runners' do
            expect(find('.gl-pagination')).not_to be_nil
          end
        end
      end
    end

    context 'when multiple project runners are configured' do
      let!(:project_runner_2) { create(:ci_runner, :project, projects: [project]) }

      it 'adds pagination to the runner list' do
        stub_const('Projects::Settings::CiCdController::NUMBER_OF_RUNNERS_PER_PAGE', 1)

        visit project_runners_path(project)

        expect(find('.gl-pagination')).not_to be_nil
      end
    end
  end

  context 'when a project runner exists in another project' do
    let_it_be(:another_project) { create(:project, maintainers: user, organization: project.organization) }
    let_it_be(:project_runner) { create(:ci_runner, :project, projects: [another_project]) }

    it 'user enables and disables a project runner' do
      visit project_runners_path(project)

      within_testid 'available_project_runners' do
        click_on 'Enable for this project'
      end

      expect(find_by_testid('assigned_project_runners')).to have_content(project_runner.display_name)

      within_testid 'assigned_project_runners' do
        click_on 'Disable for this project'
      end

      expect(find_by_testid('available_project_runners')).to have_content(project_runner.display_name)
    end
  end

  context 'with instance runner text' do
    context 'when application settings have shared_runners_text' do
      let(:shared_runners_text) { 'custom **instance** runners description' }
      let(:shared_runners_html) { 'custom instance runners description' }

      before do
        stub_application_setting(shared_runners_text: shared_runners_text)
      end

      it 'user sees instance runners description' do
        visit project_runners_path(project)

        within_testid('shared-runners-description') do
          expect(page).not_to have_content('The same instance runner executes code from multiple projects')
          expect(page).to have_content(shared_runners_html)
        end
      end
    end

    context 'when application settings have an unsafe link in shared_runners_text' do
      let(:shared_runners_text) { '<a href="javascript:alert(\'xss\')">link</a>' }

      before do
        stub_application_setting(shared_runners_text: shared_runners_text)
      end

      it 'user sees no link' do
        visit project_runners_path(project)

        within_testid('shared-runners-description') do
          expect(page).to have_content('link')
          expect(page).not_to have_link('link')
        end
      end
    end

    context 'when application settings have an unsafe image in shared_runners_text' do
      let(:shared_runners_text) { '<img src="404.png" onerror="alert(\'xss\')"/>' }

      before do
        stub_application_setting(shared_runners_text: shared_runners_text)
      end

      it 'user sees image safely' do
        visit project_runners_path(project)

        within_testid('shared-runners-description') do
          expect(page).to have_css('img')
          expect(page).not_to have_css('img[onerror]')
        end
      end
    end
  end

  context 'when updating a runner' do
    before do
      visit edit_project_runner_path(project, project_runner)
    end

    it_behaves_like 'submits edit runner form' do
      let(:runner) { project_runner }
      let(:runner_page_path) { project_runner_path(project, project_runner) }
    end
  end
end
