# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User resolves outdated diff discussions',
  :js, feature_category: :code_review_workflow do
  let(:project) { create(:project, :repository, :public) }

  let(:merge_request) do
    create(:merge_request, source_project: project, source_branch: 'csv', target_branch: 'master')
  end

  let(:outdated_diff_refs) { project.commit('926c6595b263b2a40da6b17f3e3b7ea08344fad6').diff_refs }
  let(:current_diff_refs) { merge_request.diff_refs }

  let(:outdated_position) do
    build(:text_diff_position, :added,
      file: 'files/csv/Book1.csv',
      new_line: 9,
      diff_refs: outdated_diff_refs
    )
  end

  let(:current_position) do
    build(:text_diff_position, :added,
      file: 'files/csv/Book1.csv',
      new_line: 1,
      diff_refs: current_diff_refs
    )
  end

  let!(:outdated_discussion) do
    create(
      :diff_note_on_merge_request,
      project: project,
      noteable: merge_request,
      position: outdated_position
    ).to_discussion
  end

  let!(:current_discussion) do
    create(
      :diff_note_on_merge_request,
      noteable: merge_request,
      project: project,
      position: current_position
    ).to_discussion
  end

  before do
    sign_in(merge_request.author)
  end

  context 'when a discussion was resolved by a push' do
    before do
      project.update!(resolve_outdated_diff_discussions: true)

      merge_request.update_diff_discussion_positions(
        old_diff_refs: outdated_diff_refs,
        new_diff_refs: current_diff_refs,
        current_user: merge_request.author
      )

      visit project_merge_request_path(project, merge_request)
    end

    it 'shows that as automatically resolved' do
      within(".discussion[data-discussion-id='#{outdated_discussion.id}']") do
        expect(page).not_to have_css('.discussion-body')
        expect(page).to have_content('Automatically resolved')
      end
    end

    it 'does not show that for active discussions' do
      within(".discussion[data-discussion-id='#{current_discussion.id}']") do
        expect(page).to have_css('.discussion-body', visible: true)
        expect(page).not_to have_content('Automatically resolved')
      end
    end
  end
end
