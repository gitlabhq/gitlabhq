# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > Real-time reviewers', feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:merge_request) { create(:merge_request, :simple, source_project: project, author: user) }

  before do
    sign_in(user)
    visit project_merge_request_path(project, merge_request)
  end

  it 'updates in real-time', :js do
    wait_for_requests

    # Simulate a real-time update of reviewers
    merge_request.update!(reviewer_ids: [user.id])
    GraphqlTriggers.merge_request_reviewers_updated(merge_request)

    expect(find('.reviewer')).to have_content(user.name)
  end
end
