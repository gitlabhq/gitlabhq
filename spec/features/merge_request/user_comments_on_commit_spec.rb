# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User comments on a commit', :js, feature_category: :code_review_workflow do
  include RepoHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) do
    create(:merge_request, source_project: project, source_branch: 'feature', target_branch: 'master')
  end

  # The commit must belong to the merge request so its diff note surfaces in the MR discussion.
  let(:commit) { project.commit('feature') }
  let(:commit_diff_file) { commit.diffs.diff_files.find { |file| file.text? && file.diff_lines.any?(&:added?) } }
  let(:position) do
    build(:text_diff_position, :added,
      file: commit_diff_file.new_path,
      new_line: commit_diff_file.diff_lines.find(&:added?).new_pos,
      diff_refs: commit.diff_refs
    )
  end

  let!(:note) do
    create(:diff_note_on_commit,
      project: project, commit_id: commit.id, position: position, author: user, note: 'Line is wrong')
  end

  before_all do
    project.add_maintainer(user)
  end

  before do
    sign_in(user)
  end

  # Creating the comment through the commit page UI is covered by
  # spec/features/projects/commit/comments/*. Here we only verify the cross-over: a diff
  # comment on a commit that belongs to the merge request surfaces as a thread in the MR
  # discussion (and is counted in the notes tab).
  it 'shows a commit diff comment as a thread on the merge request', :aggregate_failures do
    visit project_merge_request_path(project, merge_request)

    within('.notes .discussion') do
      expect(page).to have_content("#{user.name} #{user.to_reference} started a thread")
      expect(page).to have_content(commit_diff_file.new_path)
      expect(page).to have_content('Line is wrong')
    end

    within('.notes-tab .badge') do
      expect(page).to have_content('1')
    end
  end
end
