require 'spec_helper'

feature 'Merge request > User creates image diff notes', :js do
  include NoteInteractionHelpers

  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }

  before do
    sign_in(user)

    # Stub helper to return any blob file as image from public app folder.
    # This is necessary to run this specs since we don't display repo images in capybara.
    allow_any_instance_of(DiffHelper).to receive(:diff_file_blob_raw_url).and_return('/apple-touch-icon.png')
    allow_any_instance_of(DiffHelper).to receive(:diff_file_old_blob_raw_url).and_return('/favicon.ico')
  end

  context 'create commit diff notes' do
    commit_id = '2f63565e7aac07bcdadb654e253078b727143ec4'

    describe 'create a new diff note' do
      before do
        visit project_commit_path(project, commit_id)
        create_image_diff_note
      end

      it 'shows indicator and avatar badges, and allows collapsing/expanding the discussion notes' do
        indicator = find('.js-image-badge')
        badge = find('.image-diff-avatar-link .badge')

        expect(indicator).to have_content('1')
        expect(badge).to have_content('1')

        find('.js-diff-notes-toggle').click

        expect(page).not_to have_content('image diff test comment')

        find('.js-diff-notes-toggle').click

        expect(page).to have_content('image diff test comment')
      end
    end

    describe 'render commit diff notes' do
      let(:path) { "files/images/6049019_460s.jpg" }
      let(:commit) { project.commit('2f63565e7aac07bcdadb654e253078b727143ec4') }

      let(:note1_position) do
        Gitlab::Diff::Position.new(
          old_path: path,
          new_path: path,
          width: 100,
          height: 100,
          x: 10,
          y: 10,
          position_type: "image",
          diff_refs: commit.diff_refs
        )
      end

      let(:note2_position) do
        Gitlab::Diff::Position.new(
          old_path: path,
          new_path: path,
          width: 100,
          height: 100,
          x: 20,
          y: 20,
          position_type: "image",
          diff_refs: commit.diff_refs
        )
      end

      let!(:note1) { create(:diff_note_on_commit, commit_id: commit.id, project: project, position: note1_position, note: 'my note 1') }
      let!(:note2) { create(:diff_note_on_commit, commit_id: commit.id, project: project, position: note2_position, note: 'my note 2') }

      before do
        visit project_commit_path(project, commit.id)
        wait_for_requests
      end

      it 'render diff indicators within the image diff frame, diff notes, and avatar badge numbers' do
        expect(page).to have_css('.js-image-badge', count: 2)
        expect(page).to have_css('.diff-content .note', count: 2)
        expect(page).to have_css('.image-diff-avatar-link', text: 1)
        expect(page).to have_css('.image-diff-avatar-link', text: 2)
      end
    end
  end

  %w(inline parallel).each do |view|
    context "#{view} view" do
      let(:merge_request) { create(:merge_request_with_diffs, :with_image_diffs, source_project: project, author: user) }
      let(:path)          { "files/images/ee_repo_logo.png" }

      let(:position) do
        Gitlab::Diff::Position.new(
          old_path: path,
          new_path: path,
          width: 100,
          height: 100,
          x: 1,
          y: 1,
          position_type: "image",
          diff_refs: merge_request.diff_refs
        )
      end

      let!(:note) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, position: position) }

      describe 'creating a new diff note' do
        before do
          visit diffs_project_merge_request_path(project, merge_request, view: view)
          create_image_diff_note
        end

        it 'shows indicator and avatar badges, and allows collapsing/expanding the discussion notes' do
          indicator = find('.js-image-badge', match: :first)
          badge = find('.image-diff-avatar-link .badge', match: :first)

          expect(indicator).to have_content('1')
          expect(badge).to have_content('1')

          page.all('.js-diff-notes-toggle')[0].click
          page.all('.js-diff-notes-toggle')[1].click

          expect(page).not_to have_content('image diff test comment')

          page.all('.js-diff-notes-toggle')[0].click
          page.all('.js-diff-notes-toggle')[1].click

          expect(page).to have_content('image diff test comment')
        end
      end
    end
  end

  describe 'discussion tab polling' do
    let(:merge_request) { create(:merge_request_with_diffs, :with_image_diffs, source_project: project, author: user) }
    let(:path)          { "files/images/ee_repo_logo.png" }

    let(:position) do
      Gitlab::Diff::Position.new(
        old_path: path,
        new_path: path,
        width: 100,
        height: 100,
        x: 50,
        y: 50,
        position_type: "image",
        diff_refs: merge_request.diff_refs
      )
    end

    before do
      visit project_merge_request_path(project, merge_request)
    end

    it 'render diff indicators within the image frame' do
      diff_note = create(:diff_note_on_merge_request, project: project, noteable: merge_request, position: position)

      wait_for_requests

      expect(page).to have_selector('.image-comment-badge')
      expect(page).to have_content(diff_note.note)
    end
  end

  describe 'image view modes' do
    before do
      visit project_commit_path(project, '2f63565e7aac07bcdadb654e253078b727143ec4')
    end

    it 'resizes image in onion skin view mode' do
      find('.view-modes-menu .onion-skin').click

      expect(find('.onion-skin-frame')['style']).to match('width: 228px; height: 240px;')
    end

    it 'resets onion skin view mode opacity when toggling between view modes' do
      find('.view-modes-menu .onion-skin').click

      # Simulate dragging onion-skin slider
      drag_and_drop_by(find('.dragger'), -30, 0)

      expect(find('.onion-skin-frame .frame.added', visible: false)['style']).not_to match('opacity: 1;')

      find('.view-modes-menu .swipe').click
      find('.view-modes-menu .onion-skin').click

      expect(find('.onion-skin-frame .frame.added', visible: false)['style']).to match('opacity: 1;')
    end
  end

  def drag_and_drop_by(element, right_by, down_by)
    page.driver.browser.action.drag_and_drop_by(element.native, right_by, down_by).perform
  end

  def create_image_diff_note
    find('.js-add-image-diff-note-button', match: :first).click
    page.all('.js-add-image-diff-note-button')[0].click
    find('.diff-content .note-textarea').native.send_keys('image diff test comment')
    click_button 'Comment'
    wait_for_requests
  end
end
