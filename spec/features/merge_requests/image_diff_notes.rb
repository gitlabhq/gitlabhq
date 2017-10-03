require 'spec_helper'

feature 'Diff note avatars', js: true do
  include NoteInteractionHelpers

  let(:user)          { create(:user) }
  let(:project)       { create(:project, :public, :repository) }
  let(:merge_request) { create(:merge_request_with_diffs, :with_image_diffs, source_project: project, author: user, title: "Added images and changes") }
  let(:path)          { "files/images/ee_repo_logo.png" }
  let(:position) do
    Gitlab::Diff::Position.new(
      old_path: path,
      new_path: path,
      width: 100,
      height: 100,
      x_axis: 1,
      y_axis: 1,
      position_type: "image",
      diff_refs: merge_request.diff_refs
    )
  end

  let!(:note) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, position: position) }

  before do
    project.team << [user, :master]
    sign_in user

    page.driver.set_cookie('sidebar_collapsed', 'true')
  end

  context 'commit view' do
    describe 'creating a new diff note' do
      before do
        visit project_commit_path(project, '2f63565e7aac07bcdadb654e253078b727143ec4')
        create_image_diff_note
      end

      it 'shows indicator badge on image diff' do
        indicator = find('.js-image-badge')

        expect(indicator).to have_content('1')
      end

      it 'shows the avatar badge on the new note' do
        badge = find('.image-diff-avatar-link .badge')

        expect(badge).to have_content('1')
      end

      it 'allows collapsing the discussion notes' do
        find('.js-diff-notes-toggle').click

        expect(page).not_to have_content('image diff test comment')
      end

      it 'allows expanding discussion notes' do
        find('.js-diff-notes-toggle').click
        find('.js-diff-notes-toggle').click

        expect(page).to have_content('image diff test comment')
      end
    end

    describe 'render diff notes' do
      commit_id = '2f63565e7aac07bcdadb654e253078b727143ec4'

      let!(:note2) { create(:note_on_commit, commit_id: commit_id, project: project, note: 'my note 2') }
      let!(:note3) { create(:note_on_commit, commit_id: commit_id, project: project, note: 'my note 3') }

      before do
        visit project_commit_path(project, commit_id)
      end

      it 'render diff indicators within the image diff frame' do
        expect(page).to have_css('.js-image-badge', count: 2)
      end

      it 'shows the diff notes' do
        expect(page).to have_css('.diff-content .note', count: 2)
      end

      it 'shows the diff notes with correct avatar badge numbers' do
        first_note_avatar = find('.image-diff-avatar-link', match: :first)
        second_note_avatar = find('.image-diff-avatar-link', match: :second)

        expect(first_note_avatar).to have_content("1")
        expect(second_note_avatar).to have_content("2")
      end
    end
  end

  %w(inline parallel).each do |view|
    context "#{view} view" do
      describe 'creating a new diff note', focus: true do
        before do
          visit diffs_project_merge_request_path(project, merge_request, view: view)
          create_image_diff_note
        end

        it 'shows indicator badge on image diff'do
          indicator = find('.js-image-badge', match: :first)

          expect(indicator).to have_content('1')
        end

        it 'shows the avatar badge on the new note' do
          badge = find('.image-diff-avatar-link .badge', match: :first)

          expect(badge).to have_content('1')
        end

        it 'allows collapsing the discussion notes' do
          find('.js-diff-notes-toggle', match: :first).click

          expect(page).not_to have_content('image diff test comment')
        end

        it 'allows expanding discussion notes' do
          find('.js-diff-notes-toggle', match: :first).click
          find('.js-diff-notes-toggle', match: :first).click

          expect(page).to have_content('image diff test comment')
        end
      end

      describe 'render diff notes' do
        before do
          # mock a couple separate comments on the image diff
        end

        it 'render diff indicators within the image frame' do
        end

        it 'shows the diff notes' do
        end

        it 'shows the diff notes with correct avatar badge numbers' do
        end
      end
    end
  end

  context 'discussion tab' do
    before do
      visit project_merge_request_path(project, merge_request)
    end

    it 'shows the image diff frame' do
      frame = find('.js-image-frame')
    end

    it 'shows the indicator on the frame' do
    end

    it 'shows the note with a generic comment icon' do
    end
  end

end

def create_image_diff_note
  find('.js-add-image-diff-note-button').click
  find('.diff-content .note-textarea').native.send_keys('image diff test comment')
  click_button 'Comment'
  wait_for_requests
end
