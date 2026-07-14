# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User creates image diff notes', :js, feature_category: :code_review_workflow do
  include NoteInteractionHelpers
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user) { project.creator }

  before do
    sign_in(user)

    # Stub helper to return any blob file as an image from the public app folder, since we
    # don't display repo images in capybara.
    allow_any_instance_of(DiffHelper).to receive(:diff_file_blob_raw_url).and_return('/apple-touch-icon.png')
    allow_any_instance_of(DiffHelper).to receive(:diff_file_old_blob_raw_url).and_return('/favicon.png')
  end

  context 'commit image diff notes' do
    let(:path) { "files/images/6049019_460s.jpg" }
    let(:commit) { project.commit('2f63565e7aac07bcdadb654e253078b727143ec4') }

    let(:note1_position) { build(:image_diff_position, file: path, diff_refs: commit.diff_refs) }
    let(:note2_position) { build(:image_diff_position, file: path, diff_refs: commit.diff_refs) }

    let!(:note1) do
      create(:diff_note_on_commit, commit_id: commit.id, project: project, position: note1_position, note: 'my note 1')
    end

    let!(:note2) do
      create(:diff_note_on_commit, commit_id: commit.id, project: project, position: note2_position, note: 'my note 2')
    end

    before do
      visit project_commit_path(project, commit.id)
      wait_for_requests
    end

    # Creating image diff notes through the UI is exercised by the merge request contexts
    # below; here we stub the notes and assert the Rapid Diffs image viewer renders them.
    it 'renders the image diff notes', :aggregate_failures do
      expect(page).to have_testid('noteable-note-container', count: 2)
      expect(page).to have_content('my note 1')
      expect(page).to have_content('my note 2')
    end
  end

  describe 'merge request image diff notes in Rapid Diffs' do
    let_it_be_with_reload(:merge_request) do
      create(:merge_request_with_diffs, :with_image_diffs, source_project: project, author: user)
    end

    before do
      set_cookie('rapid_diffs_enabled', 'true')
    end

    it 'creates an image diff note' do
      visit diffs_project_merge_request_path(project, merge_request)

      click_button 'Add image comment', match: :first
      find_by_testid('reply-field').set('image diff test comment')
      click_button 'Comment'

      expect(page).to have_testid('image-comment-badge')
      expect(page).to have_content('image diff test comment')
    end

    context 'with an existing image diff note' do
      let(:path) { 'files/images/ee_repo_logo.png' }
      let(:position) do
        build(:image_diff_position, file: path, diff_refs: merge_request.diff_refs)
      end

      let!(:note) do
        create(:diff_note_on_merge_request, project: project, noteable: merge_request,
          position: position, note: 'existing image comment')
      end

      before do
        visit diffs_project_merge_request_path(project, merge_request)
      end

      it 'renders the discussion badge and note' do
        expect(page).to have_testid('image-comment-badge')
        expect(page).to have_content('existing image comment')
      end

      it 'edits the note' do
        find('[aria-label^="Edit comment"]', match: :first).click
        find_by_testid('reply-field').set('edited image comment')
        click_button 'Save comment'

        expect(page).to have_content('edited image comment')
        expect(page).not_to have_content('existing image comment')
      end

      it 'deletes the note' do
        accept_gl_confirm(button_text: 'Delete comment') do
          find('[title="More actions"] button', match: :first).click
          click_button 'Delete comment'
        end

        expect(page).not_to have_content('existing image comment')
        expect(page).not_to have_testid('image-comment-badge')
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
    it 'resets opacity when toggling between view modes', quarantine: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/9342' do
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

    describe 'swipe view', quarantine: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/9345' do
      before do
        switch_to_swipe_view
      end

      it_behaves_like 'swipe view'
    end
  end

  def drag_and_drop_by(element, right_by, down_by)
    page.driver.browser.action.drag_and_drop_by(element.native, right_by, down_by).perform
  end

  def left_position(element)
    page.evaluate_script("document.querySelectorAll('#{element}')[0].getBoundingClientRect().left;")
  end
end
