# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User edits a comment on a commit", :js, feature_category: :source_code_management do
  include Features::NotesHelpers
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
    new_comment_text = "+1 Awesome!"

    page.within(".main-notes-list") do
      note = find(".note")
      note.hover

      note.find(".js-note-edit").click
    end

    page.find(".current-note-edit-form textarea")

    page.within(".current-note-edit-form") do
      fill_in("note[note]", with: new_comment_text)
      click_button("Save comment")
    end

    wait_for_requests

    page.within(".note") do
      expect(page).to have_content(new_comment_text)
    end
  end
end
