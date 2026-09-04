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
  end

  it "edits comment" do
    visit(project_commit_path(project, sample_commit.id))

    add_note("XML attached")

    new_comment_text = "+1 Awesome!"

    within_testid('commit-timeline') do
      within_testid('noteable-note-container') do |scope|
        scope.hover
        find_button("Edit comment").click
        fill_in("note[note]", with: new_comment_text)
        click_button("Save comment")
        expect(scope).to have_content(new_comment_text)
      end
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

    it 'allows the tasks to be checked', :aggregate_failures do
      expect(page).to have_selector('li.task-list-item', count: 2)
      expect(page).to have_selector('li.task-list-item input[checked]', count: 0)

      # Click one note at a time with fresh finders: elements cached by `all` are not
      # reloadable, so a re-render between the two clicks goes stale or swallows the
      # second click. Waiting for `.enabled` also ensures TaskList JS has initialised,
      # because clicking a still-disabled checkbox silently does nothing.
      # The toggle produces no visible change until the page is reloaded, so wait on the
      # persisted note instead before clicking the next checkbox.
      Note.where(project: project, commit_id: sample_commit.id).order(:id).each do |note|
        within("#note_#{note.id}") do
          find('li.task-list-item.enabled .task-list-item-checkbox').click
        end

        wait_for("task list toggle to persist for note #{note.id}", polling_interval: 0.1) do
          note.reload.note.include?('[x]')
        end
      end

      visit(project_commit_path(project, sample_commit.id))

      expect(page).to have_selector('li.task-list-item', count: 2)
      expect(page).to have_selector('li.task-list-item input[checked]', count: 2)
    end
  end
end
