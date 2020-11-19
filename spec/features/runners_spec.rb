# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Runners' do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context 'when user opens runners page' do
    let(:project) { create(:project) }

    before do
      project.add_maintainer(user)
    end

    it 'user can see a button to install runners on kubernetes clusters' do
      visit project_runners_path(project)

      expect(page).to have_link('Install Runner on Kubernetes', href: project_clusters_path(project))
    end
  end

  context 'when a project has enabled shared_runners' do
    let(:project) { create(:project) }

    before do
      project.add_maintainer(user)
    end

    context 'when a project_type runner is activated on the project' do
      let!(:specific_runner) { create(:ci_runner, :project, projects: [project]) }

      it 'user sees the specific runner' do
        visit project_runners_path(project)

        within '.activated-specific-runners' do
          expect(page).to have_content(specific_runner.display_name)
        end

        click_on specific_runner.short_sha

        expect(page).to have_content(specific_runner.platform)
      end

      it 'user can pause and resume the specific runner' do
        visit project_runners_path(project)

        within '.activated-specific-runners' do
          expect(page).to have_content('Pause')
        end

        click_on 'Pause'

        within '.activated-specific-runners' do
          expect(page).to have_content('Resume')
        end

        click_on 'Resume'

        within '.activated-specific-runners' do
          expect(page).to have_content('Pause')
        end
      end

      it 'user removes an activated specific runner if this is last project for that runners' do
        visit project_runners_path(project)

        within '.activated-specific-runners' do
          click_on 'Remove Runner'
        end

        expect(page).not_to have_content(specific_runner.display_name)
      end

      it 'user edits the runner to be protected' do
        visit project_runners_path(project)

        within '.activated-specific-runners' do
          first('.edit-runner > a').click
        end

        expect(page.find_field('runner[access_level]')).not_to be_checked

        check 'runner_access_level'
        click_button 'Save changes'

        expect(page).to have_content 'Protected Yes'
      end

      context 'when a runner has a tag' do
        before do
          specific_runner.update(tag_list: ['tag'])
        end

        it 'user edits runner not to run untagged jobs' do
          visit project_runners_path(project)

          within '.activated-specific-runners' do
            first('.edit-runner > a').click
          end

          expect(page.find_field('runner[run_untagged]')).to be_checked

          uncheck 'runner_run_untagged'
          click_button 'Save changes'

          expect(page).to have_content 'Can run untagged jobs No'
        end
      end

      context 'when a shared runner is activated on the project' do
        let!(:shared_runner) { create(:ci_runner, :instance) }

        it 'user sees CI/CD setting page' do
          visit project_runners_path(project)

          expect(page.find('.available-shared-runners')).to have_content(shared_runner.display_name)
        end
      end
    end

    context 'when multiple runners are configured' do
      let!(:specific_runner) { create(:ci_runner, :project, projects: [project]) }
      let!(:specific_runner_2) { create(:ci_runner, :project, projects: [project]) }

      it 'adds pagination to the runner list' do
        stub_const('Projects::Settings::CiCdController::NUMBER_OF_RUNNERS_PER_PAGE', 1)

        visit project_runners_path(project)

        expect(find('.pagination')).not_to be_nil
      end
    end

    context 'when a specific runner exists in another project' do
      let(:another_project) { create(:project) }
      let!(:specific_runner) { create(:ci_runner, :project, projects: [another_project]) }

      before do
        another_project.add_maintainer(user)
      end

      it 'user enables and disables a specific runner' do
        visit project_runners_path(project)

        within '.available-specific-runners' do
          click_on 'Enable for this project'
        end

        expect(page.find('.activated-specific-runners')).to have_content(specific_runner.display_name)

        within '.activated-specific-runners' do
          click_on 'Disable for this project'
        end

        expect(page.find('.available-specific-runners')).to have_content(specific_runner.display_name)
      end
    end

    context 'when application settings have shared_runners_text' do
      let(:shared_runners_text) { 'custom **shared** runners description' }
      let(:shared_runners_html) { 'custom shared runners description' }

      before do
        stub_application_setting(shared_runners_text: shared_runners_text)
      end

      it 'user sees shared runners description' do
        visit project_runners_path(project)

        expect(page.find('.shared-runners-description')).to have_content(shared_runners_html)
      end
    end
  end

  context 'when a project has disabled shared_runners' do
    let(:project) { create(:project, shared_runners_enabled: false) }

    before do
      project.add_maintainer(user)
    end

    it 'user enables shared runners' do
      visit project_runners_path(project)

      click_on 'Enable shared runners'

      expect(page.find('.shared-runners-description')).to have_content('Disable shared runners')
    end
  end

  context 'group runners in project settings' do
    before do
      project.add_maintainer(user)
    end

    let(:group) { create :group }

    context 'as project and group maintainer' do
      before do
        group.add_maintainer(user)
      end

      context 'project with a group but no group runner' do
        let(:project) { create :project, group: group }

        it 'group runners are not available' do
          visit project_runners_path(project)

          expect(page).to have_content 'This group does not provide any group Runners yet'

          expect(page).to have_content 'Group maintainers can register group runners in the Group CI/CD settings'
          expect(page).not_to have_content 'Ask your group maintainer to set up a group Runner'
        end
      end
    end

    context 'as project maintainer' do
      context 'project without a group' do
        let(:project) { create :project }

        it 'group runners are not available' do
          visit project_runners_path(project)

          expect(page).to have_content 'This project does not belong to a group and can therefore not make use of group Runners.'
        end
      end

      context 'project with a group but no group runner' do
        let(:group) { create(:group) }
        let(:project) { create(:project, group: group) }

        it 'group runners are not available' do
          visit project_runners_path(project)

          expect(page).to have_content 'This group does not provide any group Runners yet.'

          expect(page).not_to have_content 'Group maintainers can register group runners in the Group CI/CD settings'
          expect(page).to have_content 'Ask your group maintainer to set up a group Runner.'
        end
      end

      context 'project with a group and a group runner' do
        let(:group) { create(:group) }
        let(:project) { create(:project, group: group) }
        let!(:ci_runner) { create(:ci_runner, :group, groups: [group], description: 'group-runner') }

        it 'group runners are available' do
          visit project_runners_path(project)

          expect(page).to have_content 'Available group Runners: 1'
          expect(page).to have_content 'group-runner'
        end

        it 'group runners may be disabled for a project' do
          visit project_runners_path(project)

          click_on 'Disable group Runners'

          expect(page).to have_content 'Enable group Runners'
          expect(project.reload.group_runners_enabled).to be false

          click_on 'Enable group Runners'

          expect(page).to have_content 'Disable group Runners'
          expect(project.reload.group_runners_enabled).to be true
        end
      end
    end
  end

  context 'group runners in group settings' do
    let(:group) { create(:group) }

    before do
      group.add_owner(user)
    end

    context 'group with no runners' do
      it 'there are no runners displayed' do
        visit group_settings_ci_cd_path(group)

        expect(page).to have_content 'No runners found'
      end

      it 'user can see a link to install runners on kubernetes clusters' do
        visit group_settings_ci_cd_path(group)

        expect(page).to have_link('Install Runner on Kubernetes', href: group_clusters_path(group))
      end
    end

    context 'group with a runner' do
      let!(:runner) { create(:ci_runner, :group, groups: [group], description: 'group-runner') }

      it 'the runner is visible' do
        visit group_settings_ci_cd_path(group)

        expect(page).not_to have_content 'No runners found'
        expect(page).to have_content 'Available Runners: 1'
        expect(page).to have_content 'group-runner'
      end

      it 'user can pause and resume the group runner' do
        visit group_settings_ci_cd_path(group)

        expect(page).to have_link href: pause_group_runner_path(group, runner)
        expect(page).not_to have_link href: resume_group_runner_path(group, runner)

        click_link href: pause_group_runner_path(group, runner)

        expect(page).not_to have_link href: pause_group_runner_path(group, runner)
        expect(page).to have_link href: resume_group_runner_path(group, runner)

        click_link href: resume_group_runner_path(group, runner)

        expect(page).to have_link href: pause_group_runner_path(group, runner)
        expect(page).not_to have_link href: resume_group_runner_path(group, runner)
      end

      it 'user can view runner details' do
        visit group_settings_ci_cd_path(group)

        expect(page).to have_content(runner.display_name)

        click_on runner.short_sha

        expect(page).to have_content(runner.platform)
      end

      it 'user can remove a group runner' do
        visit group_settings_ci_cd_path(group)

        all(:link, href: group_runner_path(group, runner))[1].click

        expect(page).not_to have_content(runner.display_name)
      end

      it 'user edits the runner to be protected' do
        visit group_settings_ci_cd_path(group)

        click_link href: edit_group_runner_path(group, runner)

        expect(page.find_field('runner[access_level]')).not_to be_checked

        check 'runner_access_level'
        click_button 'Save changes'

        expect(page).to have_content 'Protected Yes'
      end

      context 'when a runner has a tag' do
        before do
          runner.update(tag_list: ['tag'])
        end

        it 'user edits runner not to run untagged jobs' do
          visit group_settings_ci_cd_path(group)

          click_link href: edit_group_runner_path(group, runner)

          expect(page.find_field('runner[run_untagged]')).to be_checked

          uncheck 'runner_run_untagged'
          click_button 'Save changes'

          expect(page).to have_content 'Can run untagged jobs No'
        end
      end
    end

    context 'group with a project runner' do
      let(:project) { create(:project, group: group) }
      let!(:runner) { create(:ci_runner, :project, projects: [project], description: 'project-runner') }

      it 'the runner is visible' do
        visit group_settings_ci_cd_path(group)

        expect(page).not_to have_content 'No runners found'
        expect(page).to have_content 'Available Runners: 1'
        expect(page).to have_content 'project-runner'
      end

      it 'user can pause and resume the project runner' do
        visit group_settings_ci_cd_path(group)

        expect(page).to have_link href: pause_group_runner_path(group, runner)
        expect(page).not_to have_link href: resume_group_runner_path(group, runner)

        click_link href: pause_group_runner_path(group, runner)

        expect(page).not_to have_link href: pause_group_runner_path(group, runner)
        expect(page).to have_link href: resume_group_runner_path(group, runner)

        click_link href: resume_group_runner_path(group, runner)

        expect(page).to have_link href: pause_group_runner_path(group, runner)
        expect(page).not_to have_link href: resume_group_runner_path(group, runner)
      end

      it 'user can view runner details' do
        visit group_settings_ci_cd_path(group)

        expect(page).to have_content(runner.display_name)

        click_on runner.short_sha

        expect(page).to have_content(runner.platform)
      end

      it 'user can remove a project runner' do
        visit group_settings_ci_cd_path(group)

        all(:link, href: group_runner_path(group, runner))[1].click

        expect(page).not_to have_content(runner.display_name)
      end

      it 'user edits the runner to be protected' do
        visit group_settings_ci_cd_path(group)

        click_link href: edit_group_runner_path(group, runner)

        expect(page.find_field('runner[access_level]')).not_to be_checked

        check 'runner_access_level'
        click_button 'Save changes'

        expect(page).to have_content 'Protected Yes'
      end

      context 'when a runner has a tag' do
        before do
          runner.update(tag_list: ['tag'])
        end

        it 'user edits runner not to run untagged jobs' do
          visit group_settings_ci_cd_path(group)

          click_link href: edit_group_runner_path(group, runner)

          expect(page.find_field('runner[run_untagged]')).to be_checked

          uncheck 'runner_run_untagged'
          click_button 'Save changes'

          expect(page).to have_content 'Can run untagged jobs No'
        end
      end
    end

    context 'group with a multi-project runner' do
      let(:project) { create(:project, group: group) }
      let(:project_2) { create(:project, group: group) }
      let!(:runner) { create(:ci_runner, :project, projects: [project, project_2], description: 'group-runner') }

      it 'user cannot remove the project runner' do
        visit group_settings_ci_cd_path(group)

        expect(all(:link, href: group_runner_path(group, runner)).length).to eq(1)
      end
    end

    context 'filtered search' do
      it 'allows user to search by status and type', :js do
        visit group_settings_ci_cd_path(group)

        find('.filtered-search').click

        page.within('#js-dropdown-hint') do
          expect(page).to have_content('Status')
          expect(page).to have_content('Type')
          expect(page).not_to have_content('Tag')
        end
      end
    end
  end
end
