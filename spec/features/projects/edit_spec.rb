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

  it 'does not have visibility radio buttons' do
    expect(page).not_to have_selector('#project_visibility_level_0')
    expect(page).not_to have_selector('#project_visibility_level_10')
    expect(page).not_to have_selector('#project_visibility_level_20')
  end

  it 'allows user to change request access settings' do
    find('#project_request_access_enabled').set(true)

    click_button 'Save changes'
    wait_for_ajax

    expect(find('#project_request_access_enabled')).to be_checked
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
