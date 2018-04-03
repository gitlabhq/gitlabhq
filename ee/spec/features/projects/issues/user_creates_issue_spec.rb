require "spec_helper"

describe "User creates issue", :js do
  let(:project) { create(:project_empty_repo, :public) }
  let(:user) { create(:user) }

  before do
    stub_licensed_features(issue_weights: true)

    project.add_developer(user)
    sign_in(user)

    visit(new_project_issue_path(project))
  end

  context "with weight set" do
    it "creates issue" do
      issue_title = "500 error on profile"
      weight = "7"

      fill_in("Title", with: issue_title)
      click_button("Weight")

      page.within(".dropdown-menu-weight") do
        click_link(weight)
      end

      click_button("Submit issue")

      page.within(".weight") do
        expect(page).to have_content(weight)
      end

      expect(page).to have_content(issue_title)
    end
  end
end
