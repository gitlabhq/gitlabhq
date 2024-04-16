# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views comment on a diff file', :js, feature_category: :code_review_workflow do
  include MergeRequestDiffHelpers
  include RepoHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:merge_request) do
    create(:merge_request_with_diffs, source_project: project, target_project: project, source_branch: 'merge-test')
  end

  let_it_be(:user) { create(:user, maintainer_of: project) }

  before do
    sign_in(user)

    visit(diffs_project_merge_request_path(project, merge_request))
  end

  context 'with invalid start_sha position' do
    before do
      diff_refs = Gitlab::Diff::DiffRefs.new(
        base_sha: merge_request.diff_refs.base_sha,
        start_sha: 'fakesha',
        head_sha: merge_request.diff_refs.head_sha
      )
      position = build(:file_diff_position, file: 'files/ruby/popen.rb', diff_refs: diff_refs)
      create(:diff_note_on_merge_request, noteable: merge_request, project: project, position: position)
    end

    it 'renders diffs' do
      visit diffs_project_merge_request_path(project, merge_request)

      expect(page).to have_selector('.diff-file')
    end

    it 'renders discussion on overview tab' do
      visit project_merge_request_path(project, merge_request)

      expect(page).to have_selector('.note-discussion')
    end
  end
end
