# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > Context commits', :js, feature_category: :code_review_workflow do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  before do
    project.add_developer(user)

    sign_in(user)

    visit commits_project_merge_request_path(project, merge_request)

    wait_for_requests
  end

  it 'opens modal', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/443415' do
    click_button 'Add previously merged commits'

    expect(page).to have_selector('#add-review-item')
    expect(page).to have_content('Add or remove previously merged commits')
  end
end
