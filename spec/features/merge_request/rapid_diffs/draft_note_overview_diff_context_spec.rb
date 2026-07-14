# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > Draft note diff context on the Overview tab', :js,
  feature_category: :code_review_workflow do
  include RapidDiffsHelpers

  let_it_be(:commented_line) { 'SOURCE CHANGE (comment on this line)' }
  let_it_be(:merge_head_line) { 91 }
  let_it_be(:base_lines) { (1..100).map { |i| "line #{i}" } }

  let_it_be(:project) do
    create(:project, :custom_repo, files: { 'big_file.txt' => "#{base_lines.join("\n")}\n" })
  end

  let_it_be(:user) { project.creator }

  let_it_be(:merge_request) do
    repo = project.repository
    target = project.default_branch

    source_lines = base_lines.dup
    source_lines.insert(80, commented_line)
    repo.add_branch(user, 'feature-src', target)
    repo.update_file(user, 'big_file.txt', "#{source_lines.join("\n")}\n",
      message: 'Source change', branch_name: 'feature-src')

    target_lines = base_lines.dup
    10.times { |k| target_lines.insert(5 + k, "MASTER INSERT #{k + 1}") }
    repo.update_file(user, 'big_file.txt', "#{target_lines.join("\n")}\n",
      message: 'Target change above', branch_name: target)

    create(:merge_request, source_project: project, target_project: project,
      source_branch: 'feature-src', target_branch: target)
  end

  before do
    sign_in(user)
    set_cookie('rapid_diffs_enabled', 'true')
  end

  it 'renders the diff context on the Overview tab after publishing the review' do
    visit diffs_project_merge_request_path(project, merge_request, view: 'inline')
    expect(page).to have_css('[data-hunk-lines]', text: commented_line)

    materialize_merge_ref(merge_request)

    select_parallel_view
    select_inline_view
    expect(page).to have_css("[data-line-number='#{merge_head_line}']")

    line_holder = find_commented_line
    click_diff_line(line_holder)
    next_discussion_row(line_holder).fill_in('note[note]', with: 'Comment on re-streamed line')

    click_button 'Start a review'
    find_by_testid('review-drawer-toggle', match: :first).click
    expect(page).to have_text('Comment on re-streamed line')
    click_button 'Submit review'
    expect(page).to have_css('[data-testid="noteable-note-container"]', text: 'Comment on re-streamed line')
    expect(page).to have_no_button('Submit review')

    find_by_testid('notes-tab', visible: true).click

    expect(page).to have_content('Comment on re-streamed line')
    expect(page).to have_content(commented_line)
  end

  def materialize_merge_ref(mr)
    MergeRequests::MergeToRefService.new(project: project, current_user: user).execute(mr)
    MergeRequests::ReloadMergeHeadDiffService.new(mr).execute
    mr.update_column(:merge_status, 'can_be_merged')
    mr.reset
  end

  def find_commented_line
    find('[data-hunk-lines]', text: commented_line, match: :first)
  end

  def next_discussion_row(line_holder)
    line_holder.find(:xpath, './following-sibling::*[@data-discussion-row][1]')
  end

  def click_diff_line(line_holder)
    page.execute_script("arguments[0].scrollIntoView({ block: 'center' })", line_holder.native)
    link = line_holder.find('[data-line-number]', match: :first)
    wait_for('new-discussion toggle to appear on the row') do
      link.hover
      has_testid?('new_discussion_toggle', context: line_holder, wait: 0.2)
    end
    find_by_testid('new_discussion_toggle', context: line_holder).click
  end
end
