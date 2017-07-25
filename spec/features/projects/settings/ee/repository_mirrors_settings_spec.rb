require 'spec_helper'

describe 'Project settings > [EE] repository', feature: true do
  include Select2Helper

  let(:user) { create(:user) }
  let(:project) { create(:project_empty_repo) }

  before do
    project.add_master(user)
    gitlab_sign_in(user)
  end

  context 'unlicensed' do
    before do
      stub_licensed_features(repository_mirrors: false)

      visit project_settings_repository_path(project)
    end

    it 'does not show pull mirror settings' do
      expect(page).to have_no_selector('#project_mirror')
      expect(page).to have_no_selector('#project_import_url')
      expect(page).to have_no_selector('#project_mirror_user_id', visible: false)
      expect(page).to have_no_selector('#project_mirror_trigger_builds')
    end

    it 'does not show push mirror settings' do
      expect(page).to have_no_selector('#project_remote_mirrors_attributes_0_enabled')
      expect(page).to have_no_selector('#project_remote_mirrors_attributes_0_url')
    end
  end

  describe 'mirror settings', :js do
    let(:user2) { create(:user) }

    before do
      project.team << [user2, :master]

      visit project_settings_repository_path(project)
    end

    it 'shows pull mirror settings' do
      expect(page).to have_selector('#project_mirror')
      expect(page).to have_selector('#project_import_url')
      expect(page).to have_selector('#project_mirror_user_id', visible: false)
      expect(page).to have_selector('#project_mirror_trigger_builds')
    end

    it 'shows push mirror settings' do
      expect(page).to have_selector('#project_remote_mirrors_attributes_0_enabled')
      expect(page).to have_selector('#project_remote_mirrors_attributes_0_url')
    end

    it 'sets mirror user' do
      page.within('.project-mirror-settings') do
        select2(user2.id, from: '#project_mirror_user_id')

        click_button('Save changes')

        expect(find('.select2-chosen')).to have_content(user.name)
      end
    end
  end
end
