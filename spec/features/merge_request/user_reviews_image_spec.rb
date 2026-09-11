# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > image review', :js, feature_category: :code_review_workflow do
  include RepoHelpers

  let(:user) { project.first_owner }
  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request_with_diffs, :with_image_diffs, source_project: project, author: user) }

  before do
    sign_in(user)

    allow_any_instance_of(DiffHelper).to receive(:diff_file_blob_raw_url).and_return('/apple-touch-icon.png')
    allow_any_instance_of(DiffHelper).to receive(:diff_file_old_blob_raw_url).and_return('/favicon.png')

    visit diffs_project_merge_request_path(merge_request.project, merge_request)

    wait_for_requests
  end

  it 'creates an image comment' do
    click_button 'Add image comment', match: :first

    find_by_testid('reply-field').set('image diff test comment')
    click_button 'Comment'

    expect(page).to have_testid('image-comment-badge')
    expect(page).to have_content('image diff test comment')
  end

  it 'leaves review',
    skip: 'Rapid Diffs image comments cannot join a batch review; ' \
      'https://gitlab.com/gitlab-org/gitlab/-/issues/628510' do
    click_button 'Add image comment', match: :first

    find_by_testid('reply-field').set('image diff test comment')
    click_button 'Start a review'

    expect(page).to have_testid('draft-note', text: 'image diff test comment')
  end
end
