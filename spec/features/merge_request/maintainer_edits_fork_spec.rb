# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'a maintainer edits files on a source-branch of an MR from a fork', :js, :sidekiq_might_not_need_inline,
  feature_category: :code_review_workflow do
  include Features::SourceEditorSpecHelpers
  include ProjectForksHelper
  let(:user) { create(:user, username: 'the-maintainer') }
  let(:target_project) { create(:project, :public, :repository) }
  let(:author) { create(:user, username: 'mr-authoring-machine') }
  let(:source_project) { fork_project(target_project, author, repository: true) }

  let(:merge_request) do
    create(
      :merge_request,
      source_project: source_project,
      target_project: target_project,
      source_branch: 'fix',
      target_branch: 'master',
      author: author,
      allow_collaboration: true
    )
  end

  before do
    target_project.add_maintainer(user)
    sign_in(user)

    visit project_merge_request_path(target_project, merge_request)
    click_link 'Changes'
    wait_for_requests

    page.within(first('.js-file-title')) do
      find('.js-diff-more-actions').click
      find('.js-edit-blob').click
    end

    wait_for_requests
  end

  it 'mentions commits will go to the source branch' do
    click_button 'Commit changes'

    expect(page).to have_content('Your changes can be committed to fix because a merge request is open.')
  end

  it 'allows committing to the source branch' do
    content = 'Updated the readme'
    editor_set_value(content)

    click_button 'Commit changes'

    within_testid('commit-change-modal') do
      click_button 'Commit changes'
    end

    wait_for_requests

    expect(page).to have_content('Your changes have been committed successfully')
    page.within '.flash-container' do
      expect(page).to have_link 'changes'
    end
    expect(page).to have_content(content)
  end
end
