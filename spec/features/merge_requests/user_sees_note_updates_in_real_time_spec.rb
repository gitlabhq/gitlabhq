# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request note updates in real time', :js, feature_category: :code_review_workflow do
  include NoteInteractionHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  before do
    visit project_merge_request_path(project, merge_request)
  end

  describe 'new notes' do
    it 'displays the new note' do
      note = create(:note, noteable: merge_request, project: project, note: 'Looks good!')

      expect(page).to have_selector("#note_#{note.id}", text: 'Looks good!')
    end
  end

  describe 'updated notes' do
    let(:note_text) { "Hello World" }
    let(:updated_text) { "Bye World" }
    let!(:existing_note) do
      create(:discussion_note_on_merge_request, noteable: merge_request, project: project, note: note_text)
    end

    it 'displays the updated note', :aggregate_failures do
      expect(page).to have_selector("#note_#{existing_note.id}", text: note_text)

      existing_note.update!(note: updated_text)
      expect(page).to have_selector("#note_#{existing_note.id}", text: updated_text)

      existing_note.resolve!(merge_request.author)
      expect(page).to have_selector(
        "#note_#{existing_note.id} .discussion-resolved-text",
        text: /\AResolved .* by #{merge_request.author.name}\z/
      )
    end
  end
end
