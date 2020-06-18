# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User deletes comments on a commit", :js do
  include Spec::Support::Helpers::Features::NotesHelpers
  include RepoHelpers

  let(:comment_text) { "XML attached" }
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    project.add_developer(user)

    visit(project_commit_path(project, sample_commit.id))

    add_note(comment_text)
  end

  it "deletes comment" do
    page.within(".note") do
      expect(page).to have_content(comment_text)
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
