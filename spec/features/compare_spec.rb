require "spec_helper"

describe "Compare", js: true do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }

  before do
    project.team << [user, :master]
    login_as user
    visit namespace_project_compare_index_path(project.namespace, project, from: "master", to: "master")
  end

  describe "branches" do
    it "should pre-populate fields" do
      expect(page.find_field("from").value).to eq("master")
    end

    it "should compare branches" do
      fill_in "from", with: "fea"
      find("#from").click

      click_link "feature"
      expect(page.find_field("from").value).to eq("feature")

      click_button "Compare"
      expect(page).to have_content "Commits"
    end
  end

  describe "tags" do
    it "should compare tags" do
      fill_in "from", with: "v1.0"
      find("#from").click

      click_link "v1.0.0"
      expect(page.find_field("from").value).to eq("v1.0.0")

      click_button "Compare"
      expect(page).to have_content "Commits"
    end
  end
end
