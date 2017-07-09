require 'rails_helper'

feature 'Project edit', feature: true, js: true do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }

  before do
    project.team << [user, :master]
    sign_in(user)

    visit edit_project_path(project)
  end

  it 'does not have visibility radio buttons' do
    expect(page).not_to have_selector('#project_visibility_level_0')
    expect(page).not_to have_selector('#project_visibility_level_10')
    expect(page).not_to have_selector('#project_visibility_level_20')
  end

  it 'allows user to change request access settings' do
    find('#project_request_access_enabled').set(true)

    click_button 'Save changes'
    wait_for_requests

    expect(find('#project_request_access_enabled')).to be_checked
  end

  context 'feature visibility' do
    context 'merge requests select' do
      it 'hides merge requests section' do
        select('Disabled', from: 'project_project_feature_attributes_merge_requests_access_level')

        expect(page).to have_selector('.merge-requests-feature', visible: false)
      end

      context 'given project with merge_requests_disabled access level' do
        let(:project) { create(:project, :merge_requests_disabled) }

        it 'hides merge requests section' do
          expect(page).to have_selector('.merge-requests-feature', visible: false)
        end
      end
    end

    context 'builds select' do
      it 'hides builds select section' do
        select('Disabled', from: 'project_project_feature_attributes_builds_access_level')

        expect(page).to have_selector('.builds-feature', visible: false)
      end

      context 'given project with builds_disabled access level' do
        let(:project) { create(:project, :builds_disabled) }

        it 'hides builds select section' do
          expect(page).to have_selector('.builds-feature', visible: false)
        end
      end
    end
  end
end
