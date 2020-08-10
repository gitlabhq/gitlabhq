# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User jumps to the next unresolved discussion', :js do
  let(:project) { create(:project, :repository) }
  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project, target_project: project, source_branch: 'merge-test')
  end

  let(:user) { create(:user) }

  before do
    create(:discussion_note, noteable: merge_request, project: project, author: user)

    project.add_maintainer(user)
    sign_in(user)

    visit(diffs_project_merge_request_path(project, merge_request))

    wait_for_requests
  end

  it 'jumps to overview tab' do
    find('.discussion-next-btn').click

    expect(page).to have_css('.notes-tab.active')
  end
end
