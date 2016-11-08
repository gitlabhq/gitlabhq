require 'spec_helper'

<<<<<<< HEAD
feature 'Global elastic search', feature: true do
=======
feature 'Global search', feature: true do
>>>>>>> ce/master
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  before do
<<<<<<< HEAD
    stub_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    Gitlab::Elastic::Helper.create_empty_index

=======
>>>>>>> ce/master
    project.team << [user, :master]
    login_with(user)
  end

<<<<<<< HEAD
  after do
    Gitlab::Elastic::Helper.delete_index
    stub_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
  end

  describe 'I search through the issues and I see pagination' do
    before do
      create_list(:issue, 21, project: project, title: 'initial')

      Gitlab::Elastic::Helper.refresh_index
=======
  describe 'I search through the issues and I see pagination' do
    before do
      allow_any_instance_of(Gitlab::SearchResults).to receive(:per_page).and_return(1)
      create_list(:issue, 2, project: project, title: 'initial')
>>>>>>> ce/master
    end

    it "has a pagination" do
      visit dashboard_projects_path

      fill_in "search", with: "initial"
      click_button "Go"

      select_filter("Issues")
      expect(page).to have_selector('.gl-pagination .page', count: 2)
    end
  end
<<<<<<< HEAD

  describe 'I search through the blobs' do
    before do
      project.repository.index_blobs

      Gitlab::Elastic::Helper.refresh_index
    end

    it "finds files" do
      visit dashboard_projects_path

      fill_in "search", with: "def"
      click_button "Go"

      select_filter("Code")

      expect(page).to have_selector('.file-content .code')
    end
  end

  describe 'I search through the commits' do
    before do
      project.repository.index_commits
      Gitlab::Elastic::Helper.refresh_index
    end

    it "finds commits" do
      visit dashboard_projects_path

      fill_in "search", with: "add"
      click_button "Go"

      select_filter("Commits")

      expect(page).to have_selector('.commit-row-description')
    end
  end
=======
>>>>>>> ce/master
end
