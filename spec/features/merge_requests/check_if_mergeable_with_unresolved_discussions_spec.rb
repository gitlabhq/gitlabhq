require 'spec_helper'

feature 'Check if mergeable with unresolved discussions', js: true do
  let(:user)           { create(:user) }
  let(:project)        { create(:project) }
  let!(:merge_request) { create(:merge_request_with_diff_notes, source_project: project, author: user) }

  before do
    sign_in user
    project.team << [user, :master]
  end

  context 'when project.only_allow_merge_if_all_discussions_are_resolved == true' do
    before do
      project.update_column(:only_allow_merge_if_all_discussions_are_resolved, true)
    end

    context 'with unresolved discussions' do
      it 'does not allow to merge' do
        visit_merge_request(merge_request)

        expect(page).not_to have_button 'Merge'
        expect(page).to have_content('There are unresolved discussions.')
      end
    end

    context 'with all discussions resolved' do
      before do
        merge_request.discussions.each { |d| d.resolve!(user) }
      end

      it 'allows MR to be merged' do
        visit_merge_request(merge_request)

        expect(page).to have_button 'Merge'
      end
    end
  end

  context 'when project.only_allow_merge_if_all_discussions_are_resolved == false' do
    before do
      project.update_column(:only_allow_merge_if_all_discussions_are_resolved, false)
    end

    context 'with unresolved discussions' do
      it 'does not allow to merge' do
        visit_merge_request(merge_request)

        expect(page).to have_button 'Merge'
      end
    end

    context 'with all discussions resolved' do
      before do
        merge_request.discussions.each { |d| d.resolve!(user) }
      end

      it 'allows MR to be merged' do
        visit_merge_request(merge_request)

        expect(page).to have_button 'Merge'
      end
    end
  end

  def visit_merge_request(merge_request)
    visit project_merge_request_path(merge_request.project, merge_request)
  end
end
