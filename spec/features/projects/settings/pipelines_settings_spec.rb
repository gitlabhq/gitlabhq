require 'spec_helper'

feature "Pipelines settings" do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }
  let(:role) { :developer }

  background do
    sign_in(user)
    project.team << [user, role]
    visit project_pipelines_settings_path(project)
  end

  context 'for developer' do
    given(:role) { :developer }

    scenario 'to be disallowed to view' do
      expect(page.status_code).to eq(404)
    end
  end

  context 'for master' do
    given(:role) { :master }

    scenario 'be allowed to change', js: true do
      fill_in('Test coverage parsing', with: 'coverage_regex')
      click_on 'Save changes'

      expect(page.status_code).to eq(200)
      expect(page).to have_button('Save changes', disabled: false)
      expect(page).to have_field('Test coverage parsing', with: 'coverage_regex')
    end

    scenario 'updates auto_cancel_pending_pipelines' do
      page.check('Auto-cancel redundant, pending pipelines')
      click_on 'Save changes'

      expect(page.status_code).to eq(200)
      expect(page).to have_button('Save changes', disabled: false)

      checkbox = find_field('project_auto_cancel_pending_pipelines')
      expect(checkbox).to be_checked
    end
  end
end
