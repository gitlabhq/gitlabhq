# frozen_string_literal: true

require "spec_helper"

describe "User edits a comment on a commit", :js do
  include Spec::Support::Helpers::Features::NotesHelpers
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    project.add_developer(user)

    visit(project_commit_path(project, sample_commit.id))

    add_note("XML attached")
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
