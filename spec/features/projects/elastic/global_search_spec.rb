require 'spec_helper'

feature 'Global elastic search', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  before do
    stub_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

    project.team << [user, :master]
    login_with(user)
  end

  after do
    stub_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
  end

  describe 'I search through the issues and I see pagination' do
    before do
      [::Project, Issue, MergeRequest, Milestone].each do |model|
        model.__elasticsearch__.create_index!
      end

      create_list(:issue, 21, project: project, title: 'initial')

      Issue.__elasticsearch__.refresh_index!
    end

    after do
      [::Project, Issue, MergeRequest, Milestone].each do |model|
        model.__elasticsearch__.delete_index!
      end
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
