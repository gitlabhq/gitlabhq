# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User creates image diff notes', :js, feature_category: :code_review_workflow do
  include NoteInteractionHelpers

  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }

  before do
    sign_in(user)

    # Stub helper to return any blob file as image from public app folder.
    # This is necessary to run this specs since we don't display repo images in capybara.
    allow_any_instance_of(DiffHelper).to receive(:diff_file_blob_raw_url).and_return('/apple-touch-icon.png')
    allow_any_instance_of(DiffHelper).to receive(:diff_file_old_blob_raw_url).and_return('/favicon.png')
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
        badge = find('.image-diff-avatar-link .design-note-pin')

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
        build(:image_diff_position, file: path, diff_refs: commit.diff_refs)
      end

      let(:note2_position) do
        build(:image_diff_position, file: path, diff_refs: commit.diff_refs)
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

  %w[inline parallel].each do |view|
    context "#{view} view" do
      let(:position) do
        build(:image_diff_position, file: path, diff_refs: merge_request.diff_refs)
      end

      let!(:note) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, position: position) }

      shared_examples 'creates image diff note' do
        before do
          visit diffs_project_merge_request_path(project, merge_request, view: view)
          wait_for_requests

          create_image_diff_note
        end

        it 'shows indicator and avatar badges, and allows collapsing/expanding the discussion notes', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/27950' do
          indicator = find('.js-image-badge', match: :first)
          badge = find('.user-avatar-link .badge', match: :first)

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

      context 'when images are not stored in LFS' do
        let(:merge_request) { create(:merge_request_with_diffs, :with_image_diffs, source_project: project, author: user) }
        let(:path)          { 'files/images/ee_repo_logo.png' }

        it_behaves_like 'creates image diff note'
      end

      context 'when images are stored in LFS' do
        let(:merge_request) { create(:merge_request, source_project: project, target_project: project, source_branch: 'png-lfs', target_branch: 'master', author: user) }
        let(:path)          { 'files/images/logo-black.png' }

        before do
          allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
          project.update_attribute(:lfs_enabled, true)
        end

        it 'shows lfs badges' do
          visit diffs_project_merge_request_path(project, merge_request, view: view)
          wait_for_requests

          expect(page.all('[data-testid="label-lfs"]', visible: :all)).not_to be_empty
        end

        it_behaves_like 'creates image diff note'
      end
    end
  end

  describe 'discussion tab polling' do
    let(:merge_request) { create(:merge_request_with_diffs, :with_image_diffs, source_project: project, author: user) }
    let(:path)          { "files/images/ee_repo_logo.png" }

    let(:position) do
      build(:image_diff_position, file: path, diff_refs: merge_request.diff_refs)
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

  shared_examples 'swipe view' do
    it 'moves the swipe handle' do
      # Simulate dragging swipe view slider
      expect { drag_and_drop_by(find('.swipe-bar'), 20, 0) }
        .to change { find('.swipe-bar')['style'] }
        .from(a_string_matching('left: 1px'))
    end

    it 'shows both images at the same position' do
      drag_and_drop_by(find('.swipe-bar'), 40, 0)

      expect(left_position('.frame.added img'))
        .to eq(left_position('.frame.deleted img'))
    end
  end

  shared_examples 'onion skin' do
    it 'resets opacity when toggling between view modes', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/393331' do
      # Simulate dragging onion-skin slider
      drag_and_drop_by(find('.dragger'), -30, 0)

      expect(find('.onion-skin-frame .frame.added', visible: false)['style']).not_to match('opacity: 1;')

      switch_to_swipe_view
      switch_to_onion_skin

      expect(find('.onion-skin-frame .frame.added', visible: false)['style']).to match('opacity: 1;')
    end
  end

  describe 'changes tab image diff' do
    let(:merge_request) { create(:merge_request, source_project: project, target_project: project, target_branch: 'master', source_branch: 'deleted-image-test', author: user) }

    before do
      visit diffs_project_merge_request_path(project, merge_request)
      click_link "Changes"
    end

    def set_image_diff_sources
      # set path of added and deleted images to something the spec can view
      page.execute_script("document.querySelector('.frame.added img').src = '/apple-touch-icon.png';")
      page.execute_script("document.querySelector('.frame.deleted img').src = '/favicon.png';")

      wait_for_requests

      expect(find('.frame.added img', visible: false)['src']).to match('/apple-touch-icon.png')
      expect(find('.frame.deleted img', visible: false)['src']).to match('/favicon.png')
    end

    def switch_to_swipe_view
      # it isn't given the .swipe class in the merge request diff
      find('.view-modes-menu li:nth-child(2)').click
      expect(find('.view-modes-menu li.active')).to have_content('Swipe')

      set_image_diff_sources
    end

    def switch_to_onion_skin
      # it isn't given the .onion-skin class in the merge request diff
      find('.view-modes-menu li:nth-child(3)').click
      expect(find('.view-modes-menu li.active')).to have_content('Onion skin')

      set_image_diff_sources
    end

    describe 'onion skin' do
      before do
        switch_to_onion_skin
      end

      it_behaves_like 'onion skin'
    end

    describe 'swipe view', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/209999' do
      before do
        switch_to_swipe_view
      end

      it_behaves_like 'swipe view'
    end
  end

  describe 'image view modes' do
    before do
      visit project_commit_path(project, '2f63565e7aac07bcdadb654e253078b727143ec4')
    end

    def switch_to_swipe_view
      find('.view-modes-menu .swipe').click
    end

    def switch_to_onion_skin
      find('.view-modes-menu .onion-skin').click
    end

    describe 'onion skin' do
      before do
        switch_to_onion_skin
      end

      it 'resizes image' do
        expect(find('.onion-skin-frame')['style']).to match('width: 198px; height: 210px;')
      end

      it_behaves_like 'onion skin'
    end

    describe 'swipe view' do
      before do
        switch_to_swipe_view
      end

      it_behaves_like 'swipe view'
    end
  end

  def drag_and_drop_by(element, right_by, down_by)
    page.driver.browser.action.drag_and_drop_by(element.native, right_by, down_by).perform
  end

  def create_image_diff_note
    wait_for_all_requests

    page.all('a', text: 'Click to expand it.', wait: false).each do |element|
      element.click
    end

    find('.js-add-image-diff-note-button', match: :first).click
    find('.diff-content .note-textarea').native.send_keys('image diff test comment')
    click_button 'Comment'
    wait_for_requests
  end

  def left_position(element)
    page.evaluate_script("document.querySelectorAll('#{element}')[0].getBoundingClientRect().left;")
  end
end
