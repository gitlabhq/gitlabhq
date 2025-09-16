# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue notes polling', :js, feature_category: :team_planning do
  include NoteInteractionHelpers

  let(:project) { create(:project, :public) }
  let(:issue) { create(:issue, project: project) }

  before do
    stub_feature_flags(work_item_view_for_issues: true)
  end

  describe 'creates' do
    it 'displays the new comment' do
      visit project_issue_path(project, issue)

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
    note.update!(note: new_text)
    wait_for_requests
  end
end
