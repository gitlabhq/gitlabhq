# frozen_string_literal: true

require 'spec_helper'

describe 'Merge request > User cherry-picks', :js do
  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, namespace: group) }
  let(:user) { project.creator }
  let(:merge_request) { create(:merge_request_with_diffs, source_project: project, author: user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'Viewing a merged merge request' do
    before do
      service = MergeRequests::MergeService.new(project, user, sha: merge_request.diff_head_sha)

      perform_enqueued_jobs do
        service.execute(merge_request)
      end
    end

    # Fast-forward merge, or merged before GitLab 8.5.
    context 'without a merge commit' do
      before do
        merge_request.merge_commit_sha = nil
        merge_request.save
      end

      it 'does not show a Cherry-pick button' do
        visit project_merge_request_path(project, merge_request)

        expect(page).not_to have_link 'Cherry-pick'
      end
    end

    context 'with a merge commit' do
      it 'shows a Cherry-pick button' do
        visit project_merge_request_path(project, merge_request)

        expect(page).to have_link 'Cherry-pick'
      end

      it 'hides the cherry pick button for an archived project' do
        project.update!(archived: true)

        visit project_merge_request_path(project, merge_request)

        expect(page).not_to have_link 'Cherry-pick'
      end
    end

    context 'and seeing the cherry-pick modal' do
      before do
        visit project_merge_request_path(project, merge_request)

        click_link('Cherry-pick')
      end

      it 'shows the cherry-pick modal' do
        expect(page).to have_content('Cherry-pick this merge request')
      end

      it 'closes the cherry-pick modal with escape keypress' do
        find('#modal-cherry-pick-commit').send_keys(:escape)

        expect(page).not_to have_content('Start a new merge request with these changes')
      end
    end
  end
end
