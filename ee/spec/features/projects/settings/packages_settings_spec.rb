require 'rails_helper'

describe 'Projects > Settings > Packages', :js do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  context 'Packages enabled in config' do
    before do
      allow(Gitlab.config.packages).to receive(:enabled).and_return(true)
    end

    it 'displays the packages toggle button' do
      visit edit_project_path(project)

      expect(page).to have_content('Packages')
      expect(page).to have_selector('input[name="project[packages_enabled]"] + button', visible: true)
    end
  end

  context 'Packages disabled in config' do
    before do
      allow(Gitlab.config.packages).to receive(:enabled).and_return(false)
    end

    it 'does not show up in UI' do
      visit edit_project_path(project)

      expect(page).not_to have_content('Packages')
    end
  end
end
