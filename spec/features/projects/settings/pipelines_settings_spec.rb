# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Projects > Settings > Pipelines settings" do
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

    it 'be allowed to change' do
      visit project_settings_ci_cd_path(project)

      fill_in('Test coverage parsing', with: 'coverage_regex')

      page.within '#js-general-pipeline-settings' do
        click_on 'Save changes'
      end

      expect(page.status_code).to eq(200)

      page.within '#js-general-pipeline-settings' do
        expect(page).to have_button('Save changes', disabled: false)
      end

      expect(page).to have_field('Test coverage parsing', with: 'coverage_regex')
    end

    it 'updates auto_cancel_pending_pipelines' do
      visit project_settings_ci_cd_path(project)

      page.check('Auto-cancel redundant, pending pipelines')
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

    describe 'runners registration token' do
      let!(:token) { project.runners_token }

      before do
        visit project_settings_ci_cd_path(project)
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
end
