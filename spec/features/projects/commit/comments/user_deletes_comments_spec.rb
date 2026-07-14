# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User deletes comments on a commit", :js, feature_category: :source_code_management do
  include Features::NotesHelpers
  include Spec::Support::Helpers::ModalHelpers
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
    within_testid('noteable-note-container') do
      expect(page).to have_content(comment_text)
    end

    within_testid('commit-timeline') do
      note = find_by_testid('noteable-note-container')
      note.hover

      find_button("More actions").click
      click_on('Delete comment')
    end

    accept_gl_confirm(button_text: 'Delete comment')

    expect(page).to have_no_testid('noteable-note-container')
  end
end
