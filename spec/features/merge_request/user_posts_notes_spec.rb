require 'rails_helper'

describe 'Merge request > User posts notes', :js do
  include NoteInteractionHelpers

  let(:project) { create(:project, :repository) }
  let(:user) { project.creator }
  let(:merge_request) do
    create(:merge_request, source_project: project, target_project: project)
  end
  let!(:note) do
    create(:note_on_merge_request, :with_attachment, noteable: merge_request,
                                                     project: project)
  end

  before do
    project.add_master(user)
    sign_in(user)
    visit project_merge_request_path(project, merge_request)
  end

  subject { page }

  describe 'the note form' do
    it 'is valid' do
      is_expected.to have_css('.js-main-target-form', visible: true, count: 1)
      expect(find('.js-main-target-form .js-comment-button').value)
        .to eq('Comment')
      page.within('.js-main-target-form') do
        expect(page).not_to have_link('Cancel')
      end
    end

    describe 'with text' do
      before do
        page.within('.js-main-target-form') do
          fill_in 'note[note]', with: 'This is awesome'
        end
      end

      it 'has enable submit button and preview button' do
        page.within('.js-main-target-form') do
          expect(page).not_to have_css('.js-comment-button[disabled]')
          expect(page).to have_css('.js-md-preview-button', visible: true)
        end
      end
    end
  end

  describe 'when posting a note' do
    before do
      page.within('.js-main-target-form') do
        fill_in 'note[note]', with: 'This is awesome!'
        find('.js-md-preview-button').click
        click_button 'Comment'
      end
    end

    it 'is added and form reset' do
      is_expected.to have_content('This is awesome!')
      page.within('.js-main-target-form') do
        expect(page).to have_no_field('note[note]', with: 'This is awesome!')
        expect(page).to have_css('.js-md-preview', visible: :hidden)
      end
      page.within('.js-main-target-form') do
        is_expected.to have_css('.js-note-text', visible: true)
      end
    end
  end

  describe 'when previewing a note' do
    it 'shows the toolbar buttons when editing a note' do
      page.within('.js-main-target-form') do
        expect(page).to have_css('.md-header-toolbar.active')
      end
    end

    it 'hides the toolbar buttons when previewing a note' do
      find('.js-md-preview-button').click
      page.within('.js-main-target-form') do
        expect(page).not_to have_css('.md-header-toolbar.active')
      end
    end
  end

  describe 'when editing a note' do
    it 'there should be a hidden edit form' do
      is_expected.to have_css('.note-edit-form:not(.mr-note-edit-form)', visible: false, count: 1)
      is_expected.to have_css('.note-edit-form.mr-note-edit-form', visible: false, count: 1)
    end

    describe 'editing the note' do
      before do
        find('.note').hover

        find('.js-note-edit').click
      end

      it 'shows the note edit form and hide the note body' do
        page.within("#note_#{note.id}") do
          expect(find('.current-note-edit-form', visible: true)).to be_visible
          expect(find('.note-edit-form', visible: true)).to be_visible
          expect(find(:css, '.note-body > .note-text', visible: false)).not_to be_visible
        end
      end

      it 'resets the edit note form textarea with the original content of the note if cancelled' do
        within('.current-note-edit-form') do
          fill_in 'note[note]', with: 'Some new content'
          find('.btn-cancel').click
          expect(find('.js-note-text', visible: false).text).to eq ''
        end
      end

      it 'allows using markdown buttons after saving a note and then trying to edit it again' do
        page.within('.current-note-edit-form') do
          fill_in 'note[note]', with: 'This is the new content'
          find('.btn-save').click
        end

        wait_for_requests
        find('.note').hover

        find('.js-note-edit').click

        page.within('.current-note-edit-form') do
          expect(find('#note_note').value).to eq('This is the new content')
          find('.js-md:first-child').click
          expect(find('#note_note').value).to eq('This is the new content****')
        end
      end

      it 'appends the edited at time to the note' do
        page.within('.current-note-edit-form') do
          fill_in 'note[note]', with: 'Some new content'
          find('.btn-save').click
        end

        page.within("#note_#{note.id}") do
          is_expected.to have_css('.note_edited_ago')
          expect(find('.note_edited_ago').text)
            .to match(/less than a minute ago/)
        end
      end
    end

    describe 'deleting attachment on legacy diff note' do
      before do
        find('.note').hover

        find('.js-note-edit').click
      end

      it 'shows the delete link' do
        page.within('.note-attachment') do
          is_expected.to have_css('.js-note-attachment-delete')
        end
      end

      it 'removes the attachment div and resets the edit form' do
        accept_confirm { find('.js-note-attachment-delete').click }
        is_expected.not_to have_css('.note-attachment')
        is_expected.not_to have_css('.current-note-edit-form')
        wait_for_requests
      end
    end
  end
end
