# frozen_string_literal: true

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

    it "creates issue", :js do
      page.within(".issue-form") do
        expect(page).to have_no_content("Assign to")
        .and have_no_content("Labels")
        .and have_no_content("Milestone")

        expect(page.find('#issue_title')['placeholder']).to eq 'Title'
        expect(page.find('#issue_description')['placeholder']).to eq 'Write a comment or drag your files here…'
      end

      issue_title = "500 error on profile"

      fill_in("Title", with: issue_title)
      first('.js-md').click
      first('.rspec-issuable-form-description').native.send_keys('Description')

      click_button("Submit issue")

      expect(page).to have_content(issue_title)
        .and have_content(user.name)
        .and have_content(project.name)
      expect(page).to have_selector('strong', text: 'Description')
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
          click_button("Preview")

          preview = find(".js-md-preview") # this element is findable only when the "Preview" link is clicked.

          expect(preview).to have_content("Nothing to preview.")

          click_button("Write")
          fill_in("Description", with: "Bug fixed :smile:")
          click_button("Preview")

          expect(preview).to have_css("gl-emoji")
          expect(textarea).not_to be_visible
        end
      end
    end

    context "with labels" do
      let(:label_titles) { %w(bug feature enhancement) }

      before do
        label_titles.each do |title|
          create(:label, project: project, title: title)
        end
      end

      it "creates issue" do
        issue_title = "500 error on profile"

        fill_in("Title", with: issue_title)
        click_button("Label")
        click_link(label_titles.first)
        click_button("Submit issue")

        expect(page).to have_content(issue_title)
          .and have_content(user.name)
          .and have_content(project.name)
          .and have_content(label_titles.first)
      end
    end

    context "with Zoom link" do
      it "adds Zoom button" do
        issue_title = "Issue containing Zoom meeting link"
        zoom_url = "https://gitlab.zoom.us/j/123456789"

        fill_in("Title", with: issue_title)
        fill_in("Description", with: zoom_url)
        click_button("Submit issue")

        expect(page).to have_link('Join Zoom meeting', href: zoom_url)
      end
    end
  end

  context "when signed in as user with special characters in their name" do
    let(:user_special) { create(:user, name: "Jon O'Shea") }

    before do
      project.add_developer(user_special)
      sign_in(user_special)

      visit(new_project_issue_path(project))
    end

    it "will correctly escape user names with an apostrophe when clicking 'Assign to me'", :js do
      first('.assign-to-me-link').click

      expect(page).to have_content(user_special.name)
      expect(page.find('input[name="issue[assignee_ids][]"]', visible: false)['data-meta']).to eq(user_special.name)
    end
  end
end
