# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > Real-time merge widget', :js, feature_category: :code_review_workflow do
  let_it_be_with_reload(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:merge_request) { create(:merge_request, :simple, source_project: project, author: user) }

  before do
    sign_in(user)
    visit project_merge_request_path(project, merge_request)
  end

  context 'when merge status changes' do
    let(:trigger_action) do
      # There are different service classes that can change the merge_status
      # so we simulate it here.
      merge_request.mark_as_unchecked!
      GraphqlTriggers.merge_request_merge_status_updated(merge_request)
    end

    let(:widget_text) { s_('mrWidget|Checking if merge request can be merged…') }

    it_behaves_like 'updates merge widget in real-time'
  end

  context 'when MR gets closed' do
    let(:trigger_action) do
      MergeRequests::CloseService
        .new(project: project, current_user: user)
        .execute(merge_request)
    end

    let(:widget_text) { s_('mrWidget|Closed by') }

    it_behaves_like 'updates merge widget in real-time'
  end

  context 'when MR gets marked as draft' do
    let(:trigger_action) do
      MergeRequests::UpdateService
        .new(project: project, current_user: user, params: { title: 'Draft: title' })
        .execute(merge_request)
    end

    let(:widget_text) { 'Merge blocked: Select Mark as ready to remove it from Draft status.' }

    it_behaves_like 'updates merge widget in real-time'
  end

  context 'when MR gets approved' do
    let(:trigger_action) do
      MergeRequests::ApprovalService
        .new(project: project, current_user: user)
        .execute(merge_request)
    end

    let(:widget_text) { _('Ready to merge!') }

    before do
      merge_request.update!(approvals_before_merge: 1)
    end

    it_behaves_like 'updates merge widget in real-time'
  end

  context 'when a new discussion is started and all threads must be resolved before merge' do
    let(:trigger_action) do
      Notes::CreateService.new(project, user, {
        merge_request_diff_head_sha: merge_request.diff_head_sha,
        noteable_id: merge_request.id,
        noteable_type: merge_request.class.name,
        note: 'Unresolved discussion',
        type: 'DiscussionNote'
      }).execute
    end

    let(:widget_text) { s_('mrWidget|Merge blocked: all threads must be resolved.') }

    before do
      project.update!(only_allow_merge_if_all_discussions_are_resolved: true)
    end

    it_behaves_like 'updates merge widget in real-time'
  end
end
