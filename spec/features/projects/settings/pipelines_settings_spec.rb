require 'spec_helper'

describe "Projects > Settings > Pipelines settings" do
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

  context 'for master' do
    let(:role) { :master }

    it 'be allowed to change' do
      visit project_settings_ci_cd_path(project)

      fill_in('Test coverage parsing', with: 'coverage_regex')
      page.within '.general-ci-settings' do
        click_on 'Save changes'
      end

      expect(page.status_code).to eq(200)
      page.within '.general-ci-settings' do
        expect(page).to have_button('Save changes', disabled: false)
      end
      expect(page).to have_field('Test coverage parsing', with: 'coverage_regex')
    end

    it 'updates auto_cancel_pending_pipelines' do
      visit project_settings_ci_cd_path(project)

      page.check('Auto-cancel redundant, pending pipelines')
      page.within '.general-ci-settings' do
        click_on 'Save changes'
      end

      expect(page.status_code).to eq(200)
      page.within '.general-ci-settings' do
        expect(page).to have_button('Save changes', disabled: false)
      end

      checkbox = find_field('project_auto_cancel_pending_pipelines')
      expect(checkbox).to be_checked
    end

    describe 'Auto DevOps' do
      it 'update auto devops settings' do
        visit project_settings_ci_cd_path(project)

        page.within '.autodevops-settings' do
          fill_in('project_auto_devops_attributes_domain', with: 'test.com')
          page.choose('project_auto_devops_attributes_enabled_false')
          click_on 'Save changes'
        end

        expect(page.status_code).to eq(200)
        expect(project.auto_devops).to be_present
        expect(project.auto_devops).not_to be_enabled
      end
    end
  end
end
