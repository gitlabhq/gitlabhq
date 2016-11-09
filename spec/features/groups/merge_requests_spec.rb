require 'spec_helper'

feature 'Group merge requests page', feature: true do
  let(:path) { merge_requests_group_path(group) }
  let(:issuable) { create(:merge_request, source_project: project, target_project: project, title: "this is my created issuable")}

  include_examples 'project features apply to issuables', MergeRequest
end
