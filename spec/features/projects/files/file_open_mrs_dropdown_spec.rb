# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > Open MRs dropdown', :js, feature_category: :source_code_management do
  include FilteredSearchHelpers

  def create_mr(branch_name, title)
    project.repository.create_branch(branch_name)

    project.repository.commit_files(
      user,
      branch_name: branch_name,
      message: "Update readme file",
      actions: [{ action: :update, file_path: file_path, content: "Updated file content" }]
    )

    create(:merge_request, source_project: project, target_branch: target_branch, source_branch: branch_name,
      title: title)
  end

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user)    { project.creator }
  let_it_be(:file_path) { 'README.md' }
  let_it_be(:mr_title) { 'Update README.md' }
  let_it_be(:source_branch) { 'open-mrs-badge-test-1' }
  let_it_be(:another_mr_title) { 'Second update to README.md' }
  let_it_be(:another_source_branch) { 'open-mrs-badge-test-2' }
  let_it_be(:target_branch) { 'master' }

  before do
    sign_in(user)

    create_mr(source_branch, mr_title)
    create_mr(another_source_branch, another_mr_title)
  end

  it 'shows correct count and lists all MRs in dropdown' do
    visit project_blob_path(project, "master/#{file_path}")

    badge = find_by_testid('open-mr-badge')
    expect(badge).to have_content('2 Open')

    badge.click
    wait_for_requests

    within_testid('disclosure-content') do
      expect(page).to have_content(mr_title)
      expect(page).to have_content(another_mr_title)

      click_link mr_title
    end

    expect(page).to have_content(mr_title)
  end
end
