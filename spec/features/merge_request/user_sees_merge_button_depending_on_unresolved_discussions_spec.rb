# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees merge button depending on unresolved threads', :js do
  let(:project)        { create(:project, :repository) }
  let(:user)           { project.creator }
  let!(:merge_request) { create(:merge_request_with_diff_notes, source_project: project, author: user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'when project.only_allow_merge_if_all_discussions_are_resolved == true' do
    before do
      project.update_column(:only_allow_merge_if_all_discussions_are_resolved, true)
      visit project_merge_request_path(project, merge_request)
    end

    context 'with unresolved threads' do
      it 'does not allow to merge' do
        expect(page).not_to have_button 'Merge'
        expect(page).to have_content('all threads must be resolved')
      end
    end

    context 'with all threads resolved' do
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

    context 'with unresolved threads' do
      it 'does not allow to merge' do
        expect(page).to have_button 'Merge'
      end
    end

    context 'with all threads resolved' do
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
