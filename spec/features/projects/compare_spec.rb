require "spec_helper"

describe "Compare", :js do
  let(:user)    { create(:user) }
  let(:project) { create(:project, :repository) }

  before do
    project.add_master(user)
    sign_in user
    visit project_compare_index_path(project, from: "master", to: "master")
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

    it "filters branches" do
      select_using_dropdown("from", "wip")

      find(".js-compare-from-dropdown .compare-dropdown-toggle").click

      expect(find(".js-compare-from-dropdown .dropdown-content")).to have_selector("li", count: 3)
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
    # find input before using to wait for the inputs visiblity
    dropdown.find('.dropdown-menu')
    dropdown.fill_in("Filter by Git revision", with: selection)
    wait_for_requests
    # find before all to wait for the items visiblity
    dropdown.find("a[data-ref=\"#{selection}\"]", match: :first)
    dropdown.all("a[data-ref=\"#{selection}\"]").last.click
  end
end
