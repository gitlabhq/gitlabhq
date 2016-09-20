require 'rails_helper'

feature 'Project edit', feature: true, js: true do
  include WaitForAjax

  let(:user)    { create(:user) }
  let(:project) { create(:project) }

  before do
    project.team << [user, :master]
    login_as(user)

    visit edit_namespace_project_path(project.namespace, project)
  end

  context 'feature visibility' do
    context 'merge requests select' do
      it 'hides merge requests section' do
        select('Disabled', from: 'project_project_feature_attributes_merge_requests_access_level')

        expect(page).to have_selector('.merge-requests-feature', visible: false)
      end

      it 'hides merge requests section after save' do
        select('Disabled', from: 'project_project_feature_attributes_merge_requests_access_level')

        expect(page).to have_selector('.merge-requests-feature', visible: false)

        click_button 'Save changes'

        wait_for_ajax

        expect(page).to have_selector('.merge-requests-feature', visible: false)
      end
    end

    context 'builds select' do
      it 'hides merge requests section' do
        select('Disabled', from: 'project_project_feature_attributes_builds_access_level')

        expect(page).to have_selector('.builds-feature', visible: false)
      end

      it 'hides merge requests section after save' do
        select('Disabled', from: 'project_project_feature_attributes_builds_access_level')

        expect(page).to have_selector('.builds-feature', visible: false)

        click_button 'Save changes'

        wait_for_ajax

        expect(page).to have_selector('.builds-feature', visible: false)
      end
    end
  end
end
