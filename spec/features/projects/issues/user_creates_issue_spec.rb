require "spec_helper"

describe "User creates issue" do
  let(:project) { create(:project_empty_repo, :public) }
  let(:user) { create(:user) }

  context "when signed in as guest" do
    before do
      project.add_guest(user)
      sign_in(user)

      visit(new_project_issue_path(project))
    end

    it "creates issue" do
      page.within(".issue-form") do
        expect(page).to have_no_content("Assign to")
        .and have_no_content("Labels")
        .and have_no_content("Milestone")
      end

      issue_title = "500 error on profile"

      fill_in("Title", with: issue_title)
      click_button("Submit issue")

      expect(page).to have_content(issue_title)
        .and have_content(user.name)
        .and have_content(project.name)
    end
  end

  context "when signed in as developer", :js do
    before do
      project.add_developer(user)
      sign_in(user)

      visit(new_project_issue_path(project))
    end

    context "when previewing" do
      it "previews content" do
        form = first(".gfm-form")
        textarea = first(".gfm-form textarea")

        page.within(form) do
          click_link("Preview")

          preview = find(".js-md-preview") # this element is findable only when the "Preview" link is clicked.

          expect(preview).to have_content("Nothing to preview.")

          click_link("Write")
          fill_in("Description", with: "Bug fixed :smile:")
          click_link("Preview")

          expect(preview).to have_css("gl-emoji")
          expect(textarea).not_to be_visible
        end
      end
    end

    context "with labels" do
      LABEL_TITLES = %w(bug feature enhancement).freeze

      before do
        LABEL_TITLES.each do |title|
          create(:label, project: project, title: title)
        end
      end

      it "creates issue" do
        issue_title = "500 error on profile"

        fill_in("Title", with: issue_title)
        click_button("Label")
        click_link(LABEL_TITLES.first)
        click_button("Submit issue")

        expect(page).to have_content(issue_title)
          .and have_content(user.name)
          .and have_content(project.name)
          .and have_content(LABEL_TITLES.first)
      end
    end
  end
end
