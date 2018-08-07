require 'spec_helper'

describe 'Project settings > [EE] repository' do
  include Select2Helper

  let(:user) { create(:user) }
  let(:project) { create(:project_empty_repo) }

  before do
    project.add_maintainer(user)
    gitlab_sign_in(user)
  end

  context 'unlicensed' do
    before do
      stub_licensed_features(repository_mirrors: false)

      visit project_settings_repository_path(project)
    end

    it 'does not show pull mirror settings', :js do
      expect(page).to have_no_selector('#project_mirror')
      expect(page).to have_no_selector('#project_import_url')
      expect(page).to have_no_selector('#project_mirror_user_id', visible: false)
      expect(page).to have_no_selector('#project_mirror_trigger_builds')
    end
  end
end
