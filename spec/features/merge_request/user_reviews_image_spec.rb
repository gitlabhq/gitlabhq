# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > image review', :js, feature_category: :code_review_workflow do
  include MergeRequestDiffHelpers
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

  it 'leaves review' do
    find('.js-add-image-diff-note-button', match: :first).click

    find('.diff-content .note-textarea').native.send_keys('image diff test comment')

    click_button('Start a review')

    wait_for_requests

    page.within(find('.draft-note')) do
      expect(page).to have_content('image diff test comment')
    end
  end
end
