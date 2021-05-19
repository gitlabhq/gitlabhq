# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User comments on commit", :js do
  include Spec::Support::Helpers::Features::NotesHelpers
  include RepoHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:comment_text) { "XML attached" }

  before_all do
    project.add_developer(user)
  end

  before do
    sign_in(user)
  end

  context "when adding new comment" do
    it "adds comment" do
      visit(project_commit_path(project, sample_commit.id))

      emoji_code = ":+1:"

      page.within(".js-main-target-form") do
        expect(page).not_to have_link("Cancel")

        fill_in("note[note]", with: "#{comment_text} #{emoji_code}")

        # Check on `Preview` tab
        click_button("Preview")

        expect(find(".js-md-preview")).to have_content(comment_text).and have_css("gl-emoji")
        expect(page).not_to have_css(".js-note-text")

        # Check on `Write` tab
        click_button("Write")

        expect(page).to have_field("note[note]", with: "#{comment_text} #{emoji_code}")

        # Submit comment from the `Preview` tab to get rid of a separate `it` block
        # which would specially tests if everything gets cleared from the note form.
        click_button("Preview")
        click_button("Comment")
      end

      wait_for_requests

      page.within(".note") do
        expect(page).to have_content(comment_text).and have_css("gl-emoji")
      end

      page.within(".js-main-target-form") do
        expect(page).to have_field("note[note]", with: "").and have_no_css(".js-md-preview")
      end
    end
  end

  context "when editing comment" do
    before do
      visit(project_commit_path(project, sample_commit.id))

      add_note(comment_text)
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

  context "when deleting comment" do
    before do
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

  context 'when checking task lists' do
    let(:note_with_task) do
      <<-EOT.strip_heredoc

      - [ ] Task 1
      EOT
    end

    before do
      create(:note_on_commit, project: project, commit_id: sample_commit.id, note: note_with_task, author: user)
      create(:note_on_commit, project: project, commit_id: sample_commit.id, note: note_with_task, author: user)

      visit(project_commit_path(project, sample_commit.id))
    end

    it 'allows the tasks to be checked' do
      expect(page).to have_selector('li.task-list-item', count: 2)
      expect(page).to have_selector('li.task-list-item input[checked]', count: 0)

      all('.task-list-item-checkbox').each do |checkbox|
        checkbox.click
      end
      wait_for_requests

      visit(project_commit_path(project, sample_commit.id))

      expect(page).to have_selector('li.task-list-item', count: 2)
      expect(page).to have_selector('li.task-list-item input[checked]', count: 2)
    end
  end
end
