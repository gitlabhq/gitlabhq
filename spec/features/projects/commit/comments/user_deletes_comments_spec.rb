# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User deletes comments on a commit", :js, feature_category: :source_code_management do
  include Features::NotesHelpers
  include Spec::Support::Helpers::ModalHelpers
  include RepoHelpers

  let(:comment_text) { "XML attached" }
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  where(:rapid_diffs_enabled) do
    [false, true]
  end

  with_them do
    before do
      stub_feature_flags(rapid_diffs_on_commit_show: rapid_diffs_enabled)
      sign_in(user)
      project.add_developer(user)

      visit(project_commit_path(project, sample_commit.id))

      add_note(comment_text)
    end

    it "deletes comment" do
      page.within(".note, [data-testid='noteable-note-container']") do
        expect(page).to have_content(comment_text)
      end

      page.within(".main-notes-list, [data-testid='commit-timeline']") do
        note = find(".note, [data-testid='noteable-note-container']")
        note.hover

        find_button("More actions").click
        click_on('Delete comment')
      end

      accept_gl_confirm(button_text: 'Delete comment')

      expect(page).not_to have_css(".note, [data-testid='noteable-note-container']")
    end
  end
end
