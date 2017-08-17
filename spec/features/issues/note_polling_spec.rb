require 'spec_helper'

feature 'Issue notes polling', :js do
  include NoteInteractionHelpers

  let(:project) { create(:project, :public) }
  let(:issue) { create(:issue, project: project) }

  describe 'creates' do
    before do
      visit project_issue_path(project, issue)
    end

    it 'displays the new comment' do
      note = create(:note, noteable: issue, project: project, note: 'Looks good!')
      wait_for_requests

      expect(page).to have_selector("#note_#{note.id}", text: 'Looks good!')
    end
  end

  describe 'updates' do
    context 'when from own user' do
      let(:user) { create(:user) }
      let(:note_text) { "Hello World" }
      let(:updated_text) { "Bye World" }
      let!(:existing_note) { create(:note, noteable: issue, project: project, author: user, note: note_text) }

      before do
        sign_in(user)
        visit project_issue_path(project, issue)
      end

      it 'displays the updated content' do
        expect(page).to have_selector("#note_#{existing_note.id}", text: note_text)

        update_note(existing_note, updated_text)

        expect(page).to have_selector("#note_#{existing_note.id}", text: updated_text)
      end

      it 'when editing but have not changed anything, and an update comes in, show warning and does not update the note' do
        click_edit_action(existing_note)

        expect(page).to have_field("note[note]", with: note_text)

        update_note(existing_note, updated_text)

        expect(page).not_to have_field("note[note]", with: updated_text)
        expect(page).to have_selector(".alert")
      end

      it 'when editing but you changed some things, an update comes in, and you press cancel, show the updated content' do
        click_edit_action(existing_note)

        expect(page).to have_field("note[note]", with: note_text)

        update_note(existing_note, updated_text)

        find("#note_#{existing_note.id} .note-edit-cancel").click

        expect(page).to have_selector("#note_#{existing_note.id}", text: updated_text)
      end
    end

    context 'when from another user' do
      let(:user1) { create(:user) }
      let(:user2) { create(:user) }
      let(:note_text) { "Hello World" }
      let(:updated_text) { "Bye World" }
      let!(:existing_note) { create(:note, noteable: issue, project: project, author: user1, note: note_text) }

      before do
        sign_in(user2)
        visit project_issue_path(project, issue)
      end

      it 'displays the updated content' do
        expect(page).to have_selector("#note_#{existing_note.id}", text: note_text)

        update_note(existing_note, updated_text)

        expect(page).to have_selector("#note_#{existing_note.id}", text: updated_text)
      end
    end

    context 'system notes' do
      let(:user) { create(:user) }
      let(:note_text) { "Some system note" }
      let!(:system_note) { create(:system_note, noteable: issue, project: project, author: user, note: note_text) }

      before do
        sign_in(user)
        visit project_issue_path(project, issue)
      end

      it 'shows the system note' do
        expect(page).to have_selector("#note_#{system_note.id}", text: note_text)
      end
    end
  end

  def update_note(note, new_text)
    note.update(note: new_text)
    wait_for_requests
  end

  def click_edit_action(note)
    note_element = find("#note_#{note.id}")

    note_element.find('.js-note-edit').click
  end
end
