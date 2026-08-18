# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User comments on a commit diff', :js,
  feature_category: :code_review_workflow do
  let_it_be(:commented_line) { 'NEW LINE TO COMMENT' }

  let_it_be(:project) do
    create(:project, :custom_repo, files: { 'f.txt' => "line 1\nline 2\nline 3\n" })
  end

  let_it_be(:user) { project.creator }

  let_it_be(:merge_request) do
    repo = project.repository
    target = project.default_branch
    repo.add_branch(user, 'feature-src', target)

    repo.update_file(user, 'f.txt', "line 1\nline 2\n#{commented_line}\nline 3\n",
      message: 'Add commented line', branch_name: 'feature-src')
    repo.update_file(user, 'f.txt', "line 1\nline 2\n#{commented_line}\nline 3\nline 4\n",
      message: 'A later commit', branch_name: 'feature-src')

    create(:merge_request, source_project: project, target_project: project,
      source_branch: 'feature-src', target_branch: target)
  end

  let_it_be(:commit_sha) do
    project.repository.commits('feature-src', limit: 5).find { |c| c.message.include?('Add commented line') }.id
  end

  before do
    sign_in(user)
    set_cookie('rapid_diffs_enabled', 'true')
  end

  it 'keeps a draft comment on the commit diff after reloading' do
    visit diffs_project_merge_request_path(project, merge_request, commit_id: commit_sha)

    line_holder = find('[data-hunk-lines]', text: commented_line, match: :first)
    click_diff_line(line_holder)
    next_discussion_row(line_holder).fill_in('note[note]', with: 'Comment on an added commit line')
    click_button 'Start a review'

    expect(page).to have_testid('review-drawer-toggle')

    visit diffs_project_merge_request_path(project, merge_request, commit_id: commit_sha)

    expect(page).to have_testid('draft-note', text: 'Comment on an added commit line')
  end

  def click_diff_line(line_holder)
    page.execute_script("arguments[0].scrollIntoView({ block: 'center' })", line_holder.native)
    link = line_holder.find('[data-line-number]', match: :first)
    wait_for('new-discussion toggle to appear on the row') do
      page.execute_script('arguments[0].blur(); arguments[0].focus();', link.native)
      has_testid?('new_discussion_toggle', context: line_holder, wait: 0.2)
    end
    find_by_testid('new_discussion_toggle', context: line_holder).click
  end

  def next_discussion_row(line_holder)
    line_holder.find(:xpath, './following-sibling::*[@data-discussion-row][1]')
  end
end
