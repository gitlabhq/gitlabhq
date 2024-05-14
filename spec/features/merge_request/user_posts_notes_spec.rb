# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User posts notes', :js, feature_category: :code_review_workflow do
  include NoteInteractionHelpers
  let_it_be(:project) { create(:project, :repository) }

  let(:user) { project.creator }
  let(:merge_request) do
    create(:merge_request, source_project: project, target_project: project)
  end

  let!(:note) do
    create(:note_on_merge_request, :with_attachment, noteable: merge_request, project: project)
  end

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_merge_request_path(project, merge_request)
  end

  subject { page }

  describe 'the note form' do
    it 'is valid' do
      is_expected.to have_css('.js-main-target-form', visible: true, count: 1)
      expect(find('.js-main-target-form')).to have_selector('button', text: 'Comment')
      page.within('.js-main-target-form') do
        expect(page).not_to have_button('Cancel')
      end
    end

    describe 'with text' do
      let(:text) { 'This is awesome' }

      before do
        page.within('.js-main-target-form') do
          fill_in 'note[note]', with: text
        end
      end

      it 'has enable submit button, preview button and saves content to local storage' do
        page.within('.js-main-target-form') do
          within_testid('comment-button') do
            expect(page).to have_css('.gl-button')
            expect(page).not_to have_css('.disabled')
          end
          expect(page).to have_css('.js-md-preview-button', visible: true)
        end

        expect(page.evaluate_script("localStorage['autosave/Note/MergeRequest/#{merge_request.id}']")).to eq(text)
      end
    end
  end

  describe 'when posting a note' do
    before do
      page.within('.js-main-target-form') do
        fill_in 'note[note]', with: 'This is awesome!'
        click_button("Preview")
        click_button 'Comment'
      end
    end

    it 'is added and form reset' do
      is_expected.to have_content('This is awesome!')
      page.within('.js-main-target-form') do
        expect(page).to have_no_field('note[note]', with: 'This is awesome!')
        expect(page).to have_css('.js-vue-md-preview', visible: :hidden)
      end
      wait_for_requests
      page.within('.js-main-target-form') do
        is_expected.to have_css('.js-note-text', visible: true)
      end
    end

    describe 'reply button' do
      before do
        visit project_merge_request_path(project, merge_request)
      end

      it 'shows a reply button' do
        reply_button = find('.js-reply-button', match: :first)

        expect(reply_button).to have_selector('[data-testid="reply-icon"]')
      end

      it 'shows reply placeholder when clicking reply button' do
        reply_button = find('.js-reply-button', match: :first)

        reply_button.click

        expect(page).to have_selector('.discussion-reply-holder')
      end
    end
  end

  describe 'replying to a comment' do
    it 'makes the discussion resolvable' do
      find('.js-reply-button').click

      page.within('.discussion-reply-holder') do
        fill_in 'note[note]', with: 'A reply'
        click_button 'Add comment now'

        expect(page).to have_button('Resolve thread')
      end
    end

    context 'when comment is deleted' do
      it 'shows an error message' do
        find('.js-reply-button').click

        page.within('.discussion-reply-holder') do
          fill_in 'note[note]', with: 'A reply'

          note.delete

          click_button 'Add comment now'

          expect(page).to have_content('Comment could not be submitted: discussion to reply to cannot be found')
        end
      end
    end
  end

  describe 'when previewing a note' do
    it 'shows the toolbar buttons when editing a note' do
      page.within('.js-main-target-form .md-header-toolbar') do
        expect(page).to have_css('button', count: 16)
      end
    end

    it 'hides the toolbar buttons when previewing a note' do
      wait_for_requests
      click_button("Preview")
      page.within('.js-main-target-form .md-header-toolbar') do
        expect(page).to have_css('button', count: 1)
      end
    end
  end

  describe 'when editing a note' do
    describe 'editing the note' do
      before do
        find('.note').hover

        find('.js-note-edit').click
      end

      it 'shows the note edit form and hide the note body' do
        page.within("#note_#{note.id}") do
          expect(find('.current-note-edit-form', visible: true)).to be_visible
          expect(find('.note-edit-form', visible: true)).to be_visible
          expect(find(:css, '.note-body .note-text', visible: false)).not_to be_visible
        end
      end

      it 'resets the edit note form textarea with the original content of the note if cancelled' do
        within('.current-note-edit-form') do
          fill_in 'note[note]', with: 'Some new content'
          find_by_testid('cancel').click
        end

        page.within('.modal') do
          click_button('Cancel editing', match: :first)
        end

        expect(find('.js-note-text').text).to eq ''
      end

      it 'allows using markdown buttons after saving a note and then trying to edit it again' do
        page.within('.current-note-edit-form') do
          fill_in 'note[note]', with: 'This is the new content'
          find('.btn-confirm').click
        end

        find('.note').hover
        wait_for_requests

        find('.js-note-edit').click

        page.within('.current-note-edit-form') do
          expect(find_field('note[note]').value).to include('This is the new content')
          first('.js-md').click
          expect(find_field('note[note]').value).to include('This is the new content****')
        end
      end

      it 'appends the edited at time to the note' do
        page.within('.current-note-edit-form') do
          fill_in 'note[note]', with: 'Some new content'
          find('.btn-confirm').click
        end

        page.within("#note_#{note.id}") do
          is_expected.to have_css('.note_edited_ago')
          expect(find('.note_edited_ago').text)
            .to match(/just now/)
        end
      end
    end

    describe 'deleting attachment on legacy diff note' do
      before do
        find('.note').hover

        find('.js-note-edit').click
      end

      # TODO: https://gitlab.com/gitlab-org/gitlab-foss/issues/48034
      xit 'shows the delete link' do
        page.within('.note-attachment') do
          is_expected.to have_css('.js-note-attachment-delete')
        end
      end

      # TODO: https://gitlab.com/gitlab-org/gitlab-foss/issues/48034
      xit 'removes the attachment div and resets the edit form' do
        accept_confirm { find('.js-note-attachment-delete').click }
        is_expected.not_to have_css('.note-attachment')
        is_expected.not_to have_css('.current-note-edit-form')
        wait_for_requests
      end
    end
  end
end
