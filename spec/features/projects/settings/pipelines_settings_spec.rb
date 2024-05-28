# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Projects > Settings > Pipelines settings", feature_category: :continuous_integration do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:role) { :developer }

  before do
    sign_in(user)
    project.add_role(user, role)
  end

  context 'for developer' do
    let(:role) { :developer }

    it 'to be disallowed to view' do
      visit project_settings_ci_cd_path(project)

      expect(page.status_code).to eq(404)
    end
  end

  context 'for maintainer' do
    let(:role) { :maintainer }

    it 'updates auto_cancel_pending_pipelines' do
      visit project_settings_ci_cd_path(project)

      page.check('Auto-cancel redundant pipelines')
      page.within '#js-general-pipeline-settings' do
        click_on 'Save changes'
      end

      expect(page.status_code).to eq(200)

      page.within '#js-general-pipeline-settings' do
        expect(page).to have_button('Save changes', disabled: false)
      end

      checkbox = find_field('project_auto_cancel_pending_pipelines')
      expect(checkbox).to be_checked
    end

    it 'updates forward_deployment_enabled' do
      visit project_settings_ci_cd_path(project)

      checkbox = find_field('project_ci_cd_settings_attributes_forward_deployment_enabled')
      expect(checkbox).to be_checked

      checkbox.set(false)

      page.within '#js-general-pipeline-settings' do
        click_on 'Save changes'
      end

      expect(page.status_code).to eq(200)

      page.within '#js-general-pipeline-settings' do
        expect(page).to have_button('Save changes', disabled: false)
      end

      checkbox = find_field('project_ci_cd_settings_attributes_forward_deployment_enabled')
      expect(checkbox).not_to be_checked
    end

    it 'disables forward deployment rollback allowed when forward deployment enabled is unchecked', :js do
      visit project_settings_ci_cd_path(project)

      forward_deployment_checkbox = find_field('project_ci_cd_settings_attributes_forward_deployment_enabled')
      forward_deployment_rollback_checkbox =
        find_field('project_ci_cd_settings_attributes_forward_deployment_rollback_allowed')
      expect(forward_deployment_checkbox).to be_checked
      expect(forward_deployment_rollback_checkbox).not_to be_disabled

      forward_deployment_checkbox.click

      expect(forward_deployment_rollback_checkbox).to be_disabled

      forward_deployment_checkbox.click

      expect(forward_deployment_rollback_checkbox).not_to be_disabled
    end

    it 'updates forward_deployment_rollback_allowed' do
      visit project_settings_ci_cd_path(project)

      checkbox = find_field('project_ci_cd_settings_attributes_forward_deployment_rollback_allowed')
      expect(checkbox).to be_checked

      checkbox.set(false)

      page.within '#js-general-pipeline-settings' do
        click_on 'Save changes'
      end

      expect(page.status_code).to eq(200)

      page.within '#js-general-pipeline-settings' do
        expect(page).to have_button('Save changes', disabled: false)
      end

      checkbox = find_field('project_ci_cd_settings_attributes_forward_deployment_rollback_allowed')
      expect(checkbox).not_to be_checked
    end

    describe 'Auto DevOps' do
      context 'when auto devops is turned on instance-wide' do
        before do
          stub_application_setting(auto_devops_enabled: true)
        end

        it 'auto devops is on by default and can be manually turned off' do
          visit project_settings_ci_cd_path(project)

          page.within '#autodevops-settings' do
            expect(find_field('project_auto_devops_attributes_enabled')).to be_checked
            expect(page).to have_content('instance enabled')
            uncheck 'Default to Auto DevOps pipeline'
            click_on 'Save changes'
          end

          expect(page.status_code).to eq(200)
          expect(project.auto_devops).to be_present
          expect(project.auto_devops).not_to be_enabled

          page.within '#autodevops-settings' do
            expect(find_field('project_auto_devops_attributes_enabled')).not_to be_checked
            expect(page).not_to have_content('instance enabled')
          end
        end
      end

      context 'when auto devops is not turned on instance-wide' do
        before do
          stub_application_setting(auto_devops_enabled: false)
        end

        it 'auto devops is off by default and can be manually turned on' do
          visit project_settings_ci_cd_path(project)

          page.within '#autodevops-settings' do
            expect(page).not_to have_content('instance enabled')
            expect(find_field('project_auto_devops_attributes_enabled')).not_to be_checked
            check 'Default to Auto DevOps pipeline'
            click_on 'Save changes'
          end

          expect(page.status_code).to eq(200)
          expect(project.auto_devops).to be_present
          expect(project.auto_devops).to be_enabled

          page.within '#autodevops-settings' do
            expect(find_field('project_auto_devops_attributes_enabled')).to be_checked
            expect(page).not_to have_content('instance enabled')
          end
        end

        context 'when auto devops is turned on group level' do
          before do
            project.update!(namespace: create(:group, :auto_devops_enabled))
          end

          it 'renders group enabled badge' do
            visit project_settings_ci_cd_path(project)

            page.within '#autodevops-settings' do
              expect(page).to have_content('group enabled')
              expect(find_field('project_auto_devops_attributes_enabled')).to be_checked
            end
          end
        end

        context 'when auto devops is turned on group parent level' do
          before do
            group = create(:group, parent: create(:group, :auto_devops_enabled))
            project.update!(namespace: group)
          end

          it 'renders group enabled badge' do
            visit project_settings_ci_cd_path(project)

            page.within '#autodevops-settings' do
              expect(page).to have_content('group enabled')
              expect(find_field('project_auto_devops_attributes_enabled')).to be_checked
            end
          end
        end
      end
    end
  end
end
