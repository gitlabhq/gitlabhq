require "spec_helper"

describe "User comments on commit", :js do
  include Spec::Support::Helpers::Features::NotesHelpers
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  COMMENT_TEXT = "XML attached".freeze

  before do
    sign_in(user)
    project.add_developer(user)

    visit(project_commit_path(project, sample_commit.id))
  end

  context "when adding new comment" do
    it "adds comment" do
      EMOJI = ":+1:".freeze

      page.within(".js-main-target-form") do
        expect(page).not_to have_link("Cancel")

        fill_in("note[note]", with: "#{COMMENT_TEXT} #{EMOJI}")

        # Check on `Preview` tab
        click_link("Preview")

        expect(find(".js-md-preview")).to have_content(COMMENT_TEXT).and have_css("gl-emoji")
        expect(page).not_to have_css(".js-note-text")

        # Check on `Write` tab
        click_link("Write")

        expect(page).to have_field("note[note]", with: "#{COMMENT_TEXT} #{EMOJI}")

        # Submit comment from the `Preview` tab to get rid of a separate `it` block
        # which would specially tests if everything gets cleared from the note form.
        click_link("Preview")
        click_button("Comment")
      end

      wait_for_requests

      page.within(".note") do
        expect(page).to have_content(COMMENT_TEXT).and have_css("gl-emoji")
      end

      page.within(".js-main-target-form") do
        expect(page).to have_field("note[note]", with: "").and have_no_css(".js-md-preview")
      end
    end
  end

  context "when editing comment" do
    before do
      add_note(COMMENT_TEXT)
    end

    it "edits comment" do
      NEW_COMMENT_TEXT = "+1 Awesome!".freeze

      page.within(".main-notes-list") do
        note = find(".note")
        note.hover

        note.find(".js-note-edit").click
      end

      page.find(".current-note-edit-form textarea")

      page.within(".current-note-edit-form") do
        fill_in("note[note]", with: NEW_COMMENT_TEXT)
        click_button("Save comment")
      end

      wait_for_requests

      page.within(".note") do
        expect(page).to have_content(NEW_COMMENT_TEXT)
      end
    end
  end

  context "when deleting comment" do
    before do
      add_note(COMMENT_TEXT)
    end

    it "deletes comment" do
      page.within(".note") do
        expect(page).to have_content(COMMENT_TEXT)
      end

      page.within(".main-notes-list") do
        note = find(".note")
        note.hover

        find(".more-actions").click
        find(".more-actions .dropdown-menu li", match: :first)

        accept_confirm { find(".js-note-delete").click }
      end

      expect(page).not_to have_css(".note")
    end
  end
end
