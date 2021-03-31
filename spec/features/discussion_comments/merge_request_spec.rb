# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Thread Comments Merge Request', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_merge_request_path(project, merge_request)

    # Wait for MR widget to load
    wait_for_requests
  end

  it_behaves_like 'thread comments for issue, epic and merge request', 'merge request'
end
