# frozen_string_literal: true
require 'spec_helper'

# This is a feature spec because the problems arrise when rendering the view for
# an actual project for which the repository is removed but the cached not
# updated.
# This can occur when the fork a merge request is created from is in the process
# of being destroyed.
RSpec.describe 'User views merged merge request from deleted fork', feature_category: :code_review_workflow do
  include ProjectForksHelper

  let(:project) { create(:project, :repository) }
  let(:source_project) { fork_project(project, nil, repository: true) }
  let(:user) { project.first_owner }
  let!(:merge_request) { create(:merge_request, :merged, source_project: source_project, target_project: project) }

  before do
    sign_in user

    fork_owner = source_project.namespace.non_invite_owner_members.first.user
    # Place the source_project in the weird in between state
    source_project.update_attribute(:pending_delete, true)
    Projects::DestroyService.new(source_project, fork_owner, {}).__send__(:trash_project_repositories!)
  end

  it 'correctly shows the merge request' do
    visit(merge_request_path(merge_request))

    expect(page).to have_content(merge_request.title)
  end
end
