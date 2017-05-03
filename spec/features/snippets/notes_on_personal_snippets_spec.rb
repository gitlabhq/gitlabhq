require 'spec_helper'

describe 'Comments on personal snippets', feature: true do
  let!(:user)    { create(:user) }
  let!(:snippet) { create(:personal_snippet, :public) }
  let!(:snippet_notes) do
    [
      create(:note_on_personal_snippet, noteable: snippet, author: user),
      create(:note_on_personal_snippet, noteable: snippet)
    ]
  end
  let!(:other_note) { create(:note_on_personal_snippet) }

  before do
    login_as user
    visit snippet_path(snippet)
  end

  subject { page }

  context 'viewing the snippet detail page' do
    it 'contains notes for a snippet with correct action icons' do
      expect(page).to have_selector('#notes-list li', count: 2)

      # comment authored by current user
      page.within("#notes-list li#note_#{snippet_notes[0].id}") do
        expect(page).to have_content(snippet_notes[0].note)
        expect(page).to have_selector('.js-note-delete')
        expect(page).to have_selector('.note-emoji-button')
      end

      page.within("#notes-list li#note_#{snippet_notes[1].id}") do
        expect(page).to have_content(snippet_notes[1].note)
        expect(page).not_to have_selector('.js-note-delete')
        expect(page).to have_selector('.note-emoji-button')
      end
    end
  end
end
