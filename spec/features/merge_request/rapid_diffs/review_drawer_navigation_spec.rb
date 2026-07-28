# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > Review drawer navigation to a draft comment', :js,
  feature_category: :code_review_workflow do
  include RapidDiffsHelpers

  let_it_be(:commented_line) { 'SOURCE CHANGE (comment on this line)' }
  let_it_be(:second_file_line) { 'CHANGE IN THE OTHER FILE' }
  let_it_be(:base_lines) { (1..100).map { |i| "line #{i}" } }

  let_it_be(:project) do
    create(:project, :custom_repo, files: {
      'a_first.txt' => "#{base_lines.join("\n")}\n",
      'z_second.txt' => "#{base_lines.join("\n")}\n"
    })
  end

  let_it_be_with_reload(:user) { project.creator }

  let_it_be(:merge_request) do
    repo = project.repository
    target = project.default_branch

    repo.add_branch(user, 'feature-src', target)

    first_lines = base_lines.dup
    first_lines.insert(80, commented_line)
    repo.update_file(user, 'a_first.txt', "#{first_lines.join("\n")}\n",
      message: 'Change first file', branch_name: 'feature-src')

    second_lines = base_lines.dup
    second_lines.insert(80, second_file_line)
    repo.update_file(user, 'z_second.txt', "#{second_lines.join("\n")}\n",
      message: 'Change second file', branch_name: 'feature-src')

    create(:merge_request, source_project: project, target_project: project,
      source_branch: 'feature-src', target_branch: target)
  end

  let(:file_by_file) { false }

  before do
    user.update!(view_diffs_file_by_file: file_by_file)
    sign_in(user)
    set_cookie('rapid_diffs_enabled', 'true')
    start_review_with_draft
  end

  shared_examples 'navigating to the draft from the review drawer' do
    it 'navigates to the draft when clicking it from the Changes tab', :aggregate_failures do
      open_review_drawer
      click_draft_in_drawer

      expect_navigated_to_draft
    end

    it 'navigates to the draft when clicking it from the Overview tab', :aggregate_failures do
      find_by_testid('notes-tab', visible: true).click
      expect(page).to have_current_path(project_merge_request_path(project, merge_request), ignore_query: true)

      open_review_drawer
      click_draft_in_drawer

      expect_navigated_to_draft
    end
  end

  context 'with all files on a single page' do
    it_behaves_like 'navigating to the draft from the review drawer'
  end

  context 'in file-by-file mode' do
    let(:file_by_file) { true }

    before do
      show_other_file
    end

    it_behaves_like 'navigating to the draft from the review drawer'
  end

  def start_review_with_draft
    visit diffs_project_merge_request_path(project, merge_request, view: 'inline')
    expect(page).to have_css('[data-hunk-lines]', text: commented_line)

    line_holder = find_commented_line
    click_diff_line(line_holder)
    next_discussion_row(line_holder).fill_in('note[note]', with: 'Draft on the diff')
    click_button 'Start a review'
    expect(page).to have_css('[data-testid="draft-note"]', text: 'Draft on the diff')
  end

  # File-by-file renders one file at a time, so move off the draft's file before navigating:
  # otherwise the draft's file is already showing and the navigation would not have to load it.
  def show_other_file
    within_testid('file-by-file-navigation') { find_by_testid('nextButton').click }
    expect(page).to have_css('[data-hunk-lines]', text: second_file_line)
    expect(page).not_to have_css('[data-hunk-lines]', text: commented_line)
  end

  def expect_navigated_to_draft
    expect(page).to have_current_path(diffs_project_merge_request_path(project, merge_request), ignore_query: true)
    expect(page).to have_css('[data-hunk-lines]', text: commented_line)
    expect(page).to have_css('[data-testid="draft-note"]', text: 'Draft on the diff')
  end

  def open_review_drawer
    find_by_testid('review-drawer-toggle', match: :first).click
    expect(page).to have_text('Draft on the diff')
  end

  def click_draft_in_drawer
    find_by_testid('preview-item-header').click
  end

  def find_commented_line
    find('[data-hunk-lines]', text: commented_line, match: :first)
  end

  def next_discussion_row(line_holder)
    line_holder.find(:xpath, './following-sibling::*[@data-discussion-row][1]')
  end

  def click_diff_line(line_holder)
    page.execute_script("arguments[0].scrollIntoView({ block: 'center' })", line_holder.native)
    wait_for('new-discussion toggle to appear on the row') do
      # Re-dispatch mouseover each attempt. Capybara#hover on an unchanged element does not
      # re-fire the event, so a hover landing before Rapid Diffs attaches its listener would
      # never recover; dispatching directly retries until the toggle controller is ready.
      line = line_holder.find('[data-line-number]', match: :first)
      page.execute_script("arguments[0].dispatchEvent(new MouseEvent('mouseover', { bubbles: true }))", line.native)
      has_testid?('new_discussion_toggle', context: line_holder, wait: 0.2)
    end
    find_by_testid('new_discussion_toggle', context: line_holder).click
  end
end
