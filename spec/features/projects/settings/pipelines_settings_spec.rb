require 'spec_helper'

feature "Pipelines settings" do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:role) { :developer }

  background do
    sign_in(user)
    project.team << [user, role]
  end

  context 'for developer' do
    given(:role) { :developer }

    scenario 'to be disallowed to view' do
      visit project_settings_ci_cd_path(project)

      expect(page.status_code).to eq(404)
    end
  end

  context 'for master' do
    given(:role) { :master }

    scenario 'be allowed to change' do
      visit project_settings_ci_cd_path(project)

      fill_in('Test coverage parsing', with: 'coverage_regex')
      click_on 'Save changes'

      expect(page.status_code).to eq(200)
      expect(page).to have_button('Save changes', disabled: false)
      expect(page).to have_field('Test coverage parsing', with: 'coverage_regex')
    end

    scenario 'updates auto_cancel_pending_pipelines' do
      visit project_settings_ci_cd_path(project)

      page.check('Auto-cancel redundant, pending pipelines')
      click_on 'Save changes'

      expect(page.status_code).to eq(200)
      expect(page).to have_button('Save changes', disabled: false)

      checkbox = find_field('project_auto_cancel_pending_pipelines')
      expect(checkbox).to be_checked
    end

    describe 'Auto DevOps' do
      it 'update auto devops settings' do
        visit project_settings_ci_cd_path(project)

        fill_in('project_auto_devops_attributes_domain', with: 'test.com')
        page.choose('project_auto_devops_attributes_enabled_false')
        click_on 'Save changes'

        expect(page.status_code).to eq(200)
        expect(project.auto_devops).to be_present
        expect(project.auto_devops).not_to be_enabled
      end

      describe 'Immediately run pipeline checkbox option', :js do
        context 'when auto devops is set to instance default (enabled)' do
          before do
            stub_application_setting(auto_devops_enabled: true)
            project.create_auto_devops!(enabled: nil)
            visit project_settings_ci_cd_path(project)
          end

          it 'does not show checkboxes on page-load' do
            expect(page).to have_selector('.js-run-auto-devops-pipeline-checkbox-wrapper.hide', count: 1, visible: false)
          end

          it 'selecting explicit disabled hides all checkboxes' do
            page.choose('project_auto_devops_attributes_enabled_false')

            expect(page).to have_selector('.js-run-auto-devops-pipeline-checkbox-wrapper.hide', count: 1, visible: false)
          end

          it 'selecting explicit enabled hides all checkboxes because we are already enabled' do
            page.choose('project_auto_devops_attributes_enabled_true')

            expect(page).to have_selector('.js-run-auto-devops-pipeline-checkbox-wrapper.hide', count: 1, visible: false)
          end
        end

        context 'when auto devops is set to instance default (disabled)' do
          before do
            stub_application_setting(auto_devops_enabled: false)
            project.create_auto_devops!(enabled: nil)
            visit project_settings_ci_cd_path(project)
          end

          it 'does not show checkboxes on page-load' do
            expect(page).to have_selector('.js-run-auto-devops-pipeline-checkbox-wrapper.hide', count: 1, visible: false)
          end

          it 'selecting explicit disabled hides all checkboxes' do
            page.choose('project_auto_devops_attributes_enabled_false')

            expect(page).to have_selector('.js-run-auto-devops-pipeline-checkbox-wrapper.hide', count: 1, visible: false)
          end

          it 'selecting explicit enabled shows a checkbox' do
            page.choose('project_auto_devops_attributes_enabled_true')

            expect(page).to have_selector('.js-run-auto-devops-pipeline-checkbox-wrapper:not(.hide)', count: 1)
          end
        end

        context 'when auto devops is set to explicit disabled' do
          before do
            stub_application_setting(auto_devops_enabled: true)
            project.create_auto_devops!(enabled: false)
            visit project_settings_ci_cd_path(project)
          end

          it 'does not show checkboxes on page-load' do
            expect(page).to have_selector('.js-run-auto-devops-pipeline-checkbox-wrapper.hide', count: 2, visible: false)
          end

          it 'selecting explicit enabled shows a checkbox' do
            page.choose('project_auto_devops_attributes_enabled_true')

            expect(page).to have_selector('.js-run-auto-devops-pipeline-checkbox-wrapper:not(.hide)', count: 1)
          end

          it 'selecting instance default (enabled) shows a checkbox' do
            page.choose('project_auto_devops_attributes_enabled_')

            expect(page).to have_selector('.js-run-auto-devops-pipeline-checkbox-wrapper:not(.hide)', count: 1)
          end
        end

        context 'when auto devops is set to explicit enabled' do
          before do
            stub_application_setting(auto_devops_enabled: false)
            project.create_auto_devops!(enabled: true)
            visit project_settings_ci_cd_path(project)
          end

          it 'does not have any checkboxes' do
            expect(page).not_to have_selector('.js-run-auto-devops-pipeline-checkbox-wrapper', visible: false)
          end
        end

        context 'when master contains a .gitlab-ci.yml file' do
          let(:project) { create(:project, :repository) }

          before do
            project.repository.create_file(user, '.gitlab-ci.yml', "script: ['test']", message: 'test', branch_name: project.default_branch)
            stub_application_setting(auto_devops_enabled: true)
            project.create_auto_devops!(enabled: false)
            visit project_settings_ci_cd_path(project)
          end

          it 'does not have any checkboxes' do
            expect(page).not_to have_selector('.js-run-auto-devops-pipeline-checkbox-wrapper', visible: false)
          end
        end
      end
    end
  end
end
