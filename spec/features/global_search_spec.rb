require 'spec_helper'

feature 'Global search' do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project, namespace: user.namespace) }

  before do
    project.team << [user, :master]
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
      expect(page).to have_selector('.gl-pagination .page', count: 2)
    end
  end
end
