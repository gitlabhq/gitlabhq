# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > Rapid Diffs > Changes tab while the merge request is preparing', :js,
  feature_category: :code_review_workflow do
  include Spec::Support::Helpers::GraphqlSubscriptionHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.creator }

  let(:merge_request) do
    create(:merge_request, :unprepared, source_project: project, target_project: project,
      merge_status: 'preparing', skip_ensure_merge_request_diff: true)
  end

  before do
    stub_feature_flags(rapid_diffs_default_on_mr_show: true)
    sign_in(user)
  end

  def finish_preparation
    MergeRequests::AfterCreateService.new(project: project, current_user: user).execute(merge_request.reset)
  end

  it 'reloads the page once the subscription reports the merge request as prepared' do
    wait_for_new_graphql_subscription('mergeRequestPrepared') do
      visit diffs_project_merge_request_path(project, merge_request)
    end
    expect(page).to have_text('Building your merge request')

    finish_preparation

    expect(page).to have_css('diff-file', wait: 30)
  end

  context 'when the merge request is prepared before the client asks for its status' do
    # The diff already exists, so preparation is a single column update. Rapid Diffs still streams
    # the existing diff behind the empty state, so the reload is asserted through the empty state
    # going away.
    let(:merge_request) do
      create(:merge_request, :unprepared, source_project: project, target_project: project,
        merge_status: 'preparing')
    end

    before do
      # Answer the client's status query only once the merge request is prepared
      allow(GitlabSchema).to receive(:execute).and_call_original
      allow(GitlabSchema).to receive(:execute)
        .with(anything, hash_including(operation_name: 'mergeRequestId'))
        .and_wrap_original do |execute, *args, **kwargs|
          wait_for('the merge request to be prepared', max_wait_time: 10) { merge_request.reset.prepared? }

          execute.call(*args, **kwargs)
        end
    end

    it 'reloads the page from the status response' do
      # https://gitlab.com/gitlab-org/quality/test-failure-issues/-/work_items/44546
      # No broadcast follows a column update, so the reload can only come from the status response.
      visit diffs_project_merge_request_path(project, merge_request)
      expect(page).to have_text('Building your merge request')

      merge_request.update_columns(prepared_at: Time.current)

      expect(page).not_to have_text('Building your merge request', wait: 30)
      expect(page).to have_css('diff-file')
    end
  end
end
