require 'spec_helper'

describe 'Global search' do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'I search through the issues and I see pagination' do
    before do
      allow_any_instance_of(Gitlab::SearchResults).to receive(:per_page).and_return(1)
      create_list(:issue, 2, project: project, title: 'initial')
    end

    it "has a pagination" do
      visit dashboard_projects_path

      fill_in "search", with: "initial"
      click_button "Go"

      select_filter("Issues")
      expect(page).to have_selector('.gl-pagination .next')
    end
  end

  describe 'users search' do
    it 'shows the found user under the Users tab' do
      create(:user, username: 'gob_bluth', name: 'Gob Bluth')

      visit dashboard_projects_path

      fill_in 'search', with: 'gob'
      click_button 'Go'

      expect(page).to have_content('Users 1')

      click_on('Users 1')

      expect(page).to have_content('Gob Bluth')
      expect(page).to have_content('@gob_bluth')
    end
  end
end
