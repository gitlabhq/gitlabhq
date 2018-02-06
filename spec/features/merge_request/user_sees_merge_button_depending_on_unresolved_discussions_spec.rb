require 'rails_helper'

describe 'Merge request > User sees merge button depending on unresolved discussions', :js do
  let(:project)        { create(:project, :repository) }
  let(:user)           { project.creator }
  let!(:merge_request) { create(:merge_request_with_diff_notes, source_project: project, author: user) }

  before do
    project.add_master(user)
    sign_in(user)
  end

  context 'when project.only_allow_merge_if_all_discussions_are_resolved == true' do
    before do
      project.update_column(:only_allow_merge_if_all_discussions_are_resolved, true)
      visit project_merge_request_path(project, merge_request)
    end

    context 'with unresolved discussions' do
      it 'does not allow to merge' do
        expect(page).not_to have_button 'Merge'
        expect(page).to have_content('There are unresolved discussions.')
      end
    end

    context 'with all discussions resolved' do
      before do
        merge_request.discussions.each { |d| d.resolve!(user) }
        visit project_merge_request_path(project, merge_request)
      end

      it 'allows MR to be merged' do
        expect(page).to have_button 'Merge'
      end
    end
  end

  context 'when project.only_allow_merge_if_all_discussions_are_resolved == false' do
    before do
      project.update_column(:only_allow_merge_if_all_discussions_are_resolved, false)
      visit project_merge_request_path(project, merge_request)
    end

    context 'with unresolved discussions' do
      it 'does not allow to merge' do
        expect(page).to have_button 'Merge'
      end
    end

    context 'with all discussions resolved' do
      before do
        merge_request.discussions.each { |d| d.resolve!(user) }
        visit project_merge_request_path(project, merge_request)
      end

      it 'allows MR to be merged' do
        expect(page).to have_button 'Merge'
      end
    end
  end
end
