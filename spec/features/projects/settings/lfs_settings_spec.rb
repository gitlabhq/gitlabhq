require 'rails_helper'

describe 'Projects > Settings > LFS settings' do
  let(:admin) { create(:admin) }
  let(:project) { create(:project) }

  context 'LFS enabled setting' do
    before do
      sign_in(admin)
    end

    it 'displays the correct elements', :js do
      allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
      visit edit_project_path(project)

      expect(page).to have_content('Git Large File Storage')
      expect(page).to have_selector('input[name="project[lfs_enabled]"] + button', visible: true)
    end
  end
end
