# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User edits a comment on a commit", :js, feature_category: :source_code_management do
  include Features::NotesHelpers
  include RepoHelpers

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

      add_note("XML attached")
    end

    it "edits comment" do
      new_comment_text = "+1 Awesome!"

      page.within(
        ".main-notes-list .note, [data-testid='commit-timeline'] [data-testid='noteable-note-container']"
      ) do |scope|
        scope.hover
        find_button("Edit comment").click
        fill_in("note[note]", with: new_comment_text)
        click_button("Save comment")
        wait_for_requests
        expect(scope).to have_content(new_comment_text)
      end
    end

    context 'when checking task lists' do
      let(:note_with_task) do
        <<~MARKDOWN

        - [ ] Task 1
        MARKDOWN
      end

      before do
        create(:note_on_commit, project: project, commit_id: sample_commit.id, note: note_with_task, author: user)
        create(:note_on_commit, project: project, commit_id: sample_commit.id, note: note_with_task, author: user)

        visit(project_commit_path(project, sample_commit.id))
      end

      it 'allows the tasks to be checked' do
        expect(page).to have_selector('li.task-list-item', count: 2)
        expect(page).to have_selector('li.task-list-item input[checked]', count: 0)

        all('.task-list-item-checkbox').each(&:click)
        wait_for_requests

        visit(project_commit_path(project, sample_commit.id))

        expect(page).to have_selector('li.task-list-item', count: 2)
        expect(page).to have_selector('li.task-list-item input[checked]', count: 2)
      end
    end
  end
end
