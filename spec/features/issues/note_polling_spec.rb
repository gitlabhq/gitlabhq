require 'spec_helper'

feature 'Issue notes polling', :feature, :js do
  include NoteInteractionHelpers

  let(:project) { create(:empty_project, :public) }
  let(:issue) { create(:issue, project: project) }

  describe 'creates' do
    before do
      visit project_issue_path(project, issue)
    end

    it 'displays the new comment' do
      note = create(:note, noteable: issue, project: project, note: 'Looks good!')
      page.execute_script('notes.refresh();')

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

      it 'has .original-note-content to compare against' do
        expect(page).to have_selector("#note_#{existing_note.id}", text: note_text)
        expect(page).to have_selector("#note_#{existing_note.id} .original-note-content", count: 1, visible: false)

        update_note(existing_note, updated_text)

        expect(page).to have_selector("#note_#{existing_note.id}", text: updated_text)
        expect(page).to have_selector("#note_#{existing_note.id} .original-note-content", count: 1, visible: false)
      end

      it 'displays the updated content' do
        expect(page).to have_selector("#note_#{existing_note.id}", text: note_text)

        update_note(existing_note, updated_text)

        expect(page).to have_selector("#note_#{existing_note.id}", text: updated_text)
      end

      it 'when editing but have not changed anything, and an update comes in, show the updated content in the textarea' do
        click_edit_action(existing_note)

        expect(page).to have_field("note[note]", with: note_text)

        update_note(existing_note, updated_text)

        expect(page).to have_field("note[note]", with: updated_text)
      end

      it 'when editing but you changed some things, and an update comes in, show a warning' do
        click_edit_action(existing_note)

        expect(page).to have_field("note[note]", with: note_text)

        find("#note_#{existing_note.id} .js-note-text").set('something random')
        update_note(existing_note, updated_text)

        expect(page).to have_selector(".alert")
      end

      it 'when editing but you changed some things, an update comes in, and you press cancel, show the updated content' do
        click_edit_action(existing_note)

        expect(page).to have_field("note[note]", with: note_text)

        find("#note_#{existing_note.id} .js-note-text").set('something random')

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

      it 'has .original-note-content to compare against' do
        expect(page).to have_selector("#note_#{existing_note.id}", text: note_text)
        expect(page).to have_selector("#note_#{existing_note.id} .original-note-content", count: 1, visible: false)

        update_note(existing_note, updated_text)

        expect(page).to have_selector("#note_#{existing_note.id}", text: updated_text)
        expect(page).to have_selector("#note_#{existing_note.id} .original-note-content", count: 1, visible: false)
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

      it 'has .original-note-content to compare against' do
        expect(page).to have_selector("#note_#{system_note.id}", text: note_text)
        expect(page).to have_selector("#note_#{system_note.id} .original-note-content", count: 1, visible: false)
      end
    end
  end

  def update_note(note, new_text)
    note.update(note: new_text)
    page.execute_script('notes.refresh();')
  end

  def click_edit_action(note)
    note_element = find("#note_#{note.id}")

    open_more_actions_dropdown(note)

    note_element.find('.js-note-edit').click
  end
end
