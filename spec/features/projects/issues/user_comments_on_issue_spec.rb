require "spec_helper"

describe "User comments on issue", :js do
  include Spec::Support::Helpers::Features::NotesHelpers

  let(:project) { create(:project_empty_repo, :public) }
  let(:issue) { create(:issue, project: project) }
  let(:user) { create(:user) }

  before do
    project.add_guest(user)
    sign_in(user)

    visit(project_issue_path(project, issue))
  end

  context "when adding comments" do
    it "adds comment" do
      content = "XML attached"
      target_form = ".js-main-target-form"

      add_note(content)

      page.within(".note") do
        expect(page).to have_content(content)
      end

      page.within(target_form) do
        find(".error-alert", visible: false)
      end
    end

    it "adds comment with code block" do
      comment = "```\nCommand [1]: /usr/local/bin/git , see [text](doc/text)\n```"

      add_note(comment)

      expect(page).to have_content(comment)
    end
  end

  context "when editing comments" do
    it "edits comment" do
      add_note("# Comment with a header")

      page.within(".note-body > .note-text") do
        expect(page).to have_content("Comment with a header").and have_no_css("#comment-with-a-header")
      end

      page.within(".main-notes-list") do
        note = find(".note")

        note.hover
        note.find(".js-note-edit").click
      end

      expect(page).to have_css(".current-note-edit-form textarea")

      comment = "+1 Awesome!"

      page.within(".current-note-edit-form") do
        fill_in("note[note]", with: comment)
        click_button("Save comment")
      end

      wait_for_requests

      page.within(".note") do
        expect(page).to have_content(comment)
      end
    end
  end
end
