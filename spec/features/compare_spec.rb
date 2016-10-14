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
    it "pre-populates fields" do
      expect(find(".js-compare-from-dropdown .dropdown-toggle-text")).to have_content("master")
      expect(find(".js-compare-to-dropdown .dropdown-toggle-text")).to have_content("master")
    end

    it "compares branches" do
      select_using_dropdown "from", "feature"
      expect(find(".js-compare-from-dropdown .dropdown-toggle-text")).to have_content("feature")

      select_using_dropdown "to", "binary-encoding"
      expect(find(".js-compare-to-dropdown .dropdown-toggle-text")).to have_content("binary-encoding")

      click_button "Compare"
      expect(page).to have_content "Commits"
    end
  end

  describe "tags" do
    it "compares tags" do
      select_using_dropdown "from", "v1.0.0"
      expect(find(".js-compare-from-dropdown .dropdown-toggle-text")).to have_content("v1.0.0")

      select_using_dropdown "to", "v1.1.0"
      expect(find(".js-compare-to-dropdown .dropdown-toggle-text")).to have_content("v1.1.0")

      click_button "Compare"
      expect(page).to have_content "Commits"
    end
  end

  def select_using_dropdown(dropdown_type, selection)
    dropdown = find(".js-compare-#{dropdown_type}-dropdown")
    dropdown.find(".compare-dropdown-toggle").click
    dropdown.fill_in("Filter by branch/tag", with: selection)
    click_link selection
  end
end
