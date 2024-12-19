# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > Batch comments', :js, feature_category: :code_review_workflow do
  include MergeRequestDiffHelpers
  include RepoHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project, target_project: project, source_branch: 'merge-test')
  end

  before do
    project.add_maintainer(user)

    sign_in(user)

    visit_diffs
  end

  it 'adds draft note' do
    write_diff_comment

    expect(find('.draft-note')).to have_content('Line is wrong')

    expect(page).to have_selector('[data-testid="review_bar_component"]')

    expect(find('[data-testid="review_bar_component"] .gl-badge')).to have_content('1')
  end

  it 'publishes review' do
    write_diff_comment

    page.within('.review-bar-content') do
      click_button 'Finish review'
      click_button 'Submit review'
    end

    wait_for_requests

    expect(page).not_to have_selector('.draft-note', text: 'Line is wrong')

    expect(page).to have_selector('.note:not(.draft-note)', text: 'Line is wrong')
  end

  it 'deletes draft note' do
    write_diff_comment

    find('.js-note-delete').click

    wait_for_requests

    page.within('.modal') do
      click_button('Delete comment', match: :first)
    end

    wait_for_requests

    expect(page).not_to have_selector('.draft-note', text: 'Line is wrong')
  end

  it 'edits draft note' do
    write_diff_comment

    find('.js-note-edit').click

    wait_for_requests

    # make sure comment form is in view
    execute_script("window.scrollBy(0, 200)")

    write_comment(text: 'Testing update', button_text: 'Save comment')

    expect(page).to have_selector('.draft-note', text: 'Testing update')
  end

  context 'draft merge request' do
    let(:merge_request) do
      create(:merge_request_with_diffs, :draft_merge_request, source_project: project, target_project: project, source_branch: 'merge-test')
    end

    it 'shows /ready command explanation' do
      text = <<~TEXT
        Example comment

        /ready
      TEXT
      write_diff_comment(text: text)

      expect(page).to have_text("Marks this merge request as ready.")
    end
  end

  context 'multiple times on the same diff line' do
    it 'shows both drafts at once' do
      write_diff_comment

      # All of the Diff helpers like click_diff_line (or write_diff_comment)
      #     fail very badly when run a second time.
      # This recreates the relevant logic.
      line = find_by_scrolling("[id='#{sample_compare.changes[0][:line_code]}']")
      line.hover
      line.find('.js-add-diff-note-button').click

      write_comment(text: 'A second draft!', button_text: 'Add to review')

      expect(page).to have_text('Line is wrong')
      expect(page).to have_text('A second draft!')
    end
  end

  context 'with image and file draft note' do
    let(:merge_request) { create(:merge_request_with_diffs, :with_image_diffs, source_project: project) }
    let!(:draft_on_text) { create(:draft_note_on_text_diff, merge_request: merge_request, author: user, path: 'README.md', note: 'Lorem ipsum on text...') }
    let!(:draft_on_image) { create(:draft_note_on_image_diff, merge_request: merge_request, author: user, path: 'files/images/ee_repo_logo.png', note: 'Lorem ipsum on an image...') }

    it 'does not show in overview' do
      visit_overview

      expect(page).to have_no_text(draft_on_text.note)
      expect(page).to have_no_text(draft_on_image.note)
    end
  end

  context 'adding single comment to review' do
    before do
      visit_overview
    end

    it 'at first does not show `Add comment to review` and `Add comment now` buttons' do
      expect(page).to have_no_button('Add comment to review')
      expect(page).to have_no_button('Add comment now')
    end

    context 'when review has started' do
      before do
        visit_diffs

        write_diff_comment

        visit_overview
      end

      it 'can add comment to review' do
        write_comment(selector: '.js-main-target-form', field: 'note-body', text: 'Its a draft comment', button_text: 'Add to review')

        expect(page).to have_selector('.draft-note', text: 'Its a draft comment')

        click_button('Pending comments')

        expect(page).to have_text('2 pending comments')
      end

      it 'can add comment right away' do
        write_comment(selector: '.js-main-target-form', field: 'note-body', text: 'Its a regular comment', button_text: 'Add comment now')

        expect(page).to have_selector('.note:not(.draft-note)', text: 'Its a regular comment')

        click_button('Pending comments')

        expect(page).to have_text('1 pending comment')
      end
    end
  end

  context 'in parallel diff' do
    before do
      find('.js-show-diff-settings').click
      find_by_testid('listbox-item-parallel').click
    end

    it 'adds draft comments to both sides' do
      write_parallel_comment('2f6fcd96b88b36ce98c38da085c795a27d92a3dd_10_9')
      write_parallel_comment('2f6fcd96b88b36ce98c38da085c795a27d92a3dd_9_9', button_text: 'Add to review', text: 'Another wrong line')

      expect(find('.new .draft-note')).to have_content('Line is wrong')
      expect(find('.old .draft-note')).to have_content('Another wrong line')

      expect(find('.review-bar-content .gl-badge')).to have_content('2')
    end
  end

  context 'thread is unresolved' do
    let!(:active_discussion) { create(:diff_note_on_merge_request, noteable: merge_request, project: project).to_discussion }

    before do
      visit_diffs
    end

    it 'publishes comment right away and resolves the thread' do
      expect(active_discussion.resolved?).to eq(false)

      write_reply_to_discussion(button_text: 'Add comment now', resolve: true)

      page.within(first('.discussions-counter')) do
        expect(page).to have_content('All threads resolved')
      end
    end

    it 'publishes review and resolves the thread' do
      expect(active_discussion.resolved?).to eq(false)

      write_reply_to_discussion(resolve: true)

      page.within('.review-bar-content') do
        click_button 'Finish review'
        click_button 'Submit review'
      end

      wait_for_requests

      page.within(first('.discussions-counter')) do
        expect(page).to have_content('All threads resolved')
      end
    end
  end

  context 'thread is resolved' do
    let!(:active_discussion) { create(:diff_note_on_merge_request, :resolved, noteable: merge_request, project: project).to_discussion }

    before do
      active_discussion.resolve!(@current_user)

      visit_diffs

      page.find('.js-diff-comment-avatar').click
    end

    it 'publishes comment right away and unresolves the thread',
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/337931' do
      expect(active_discussion.resolved?).to eq(true)

      write_reply_to_discussion(button_text: 'Add comment now', unresolve: true)

      page.within(first('.discussions-counter')) do
        expect(page).to have_content('1 unresolved thread')
      end
    end

    it 'publishes review and unresolves the thread',
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/337931' do
      expect(active_discussion.resolved?).to eq(true)

      wait_for_requests

      write_reply_to_discussion(button_text: 'Start a review', unresolve: true)

      page.within('.review-bar-content') do
        click_button 'Finish review'
        click_button 'Submit review'
      end

      wait_for_requests

      page.within(first('.discussions-counter')) do
        expect(page).to have_content('1 unresolved thread')
      end
    end
  end

  def visit_diffs
    visit diffs_project_merge_request_path(merge_request.project, merge_request)

    wait_for_requests
  end

  def visit_overview
    visit project_merge_request_path(merge_request.project, merge_request)

    wait_for_requests
  end

  def write_diff_comment(...)
    click_diff_line(find_by_scrolling("[id='#{sample_compare.changes[0][:line_code]}']"))

    write_comment(...)
  end

  def write_parallel_comment(line, **params)
    line_element = find_by_scrolling("[id='#{line}']")
    scroll_to_elements_bottom(line_element)
    line_element.hover
    find(".js-add-diff-note-button").click

    write_comment(selector: "form[data-line-code='#{line}']", **params)
  end

  def write_comment(selector: '.js-discussion-note-form', field: 'note_note', button_text: 'Start a review', text: 'Line is wrong')
    page.within(selector) do
      fill_in(field, with: text)
      click_button(button_text)
    end

    wait_for_requests
  end

  def write_reply_to_discussion(button_text: 'Start a review', text: 'Line is wrong', resolve: false, unresolve: false)
    page.within(first('.diff-files-holder .discussion-reply-holder')) do
      find_field('Reply…', match: :first).click

      fill_in('note_note', with: text)

      if resolve
        page.check('Resolve thread')
      end

      if unresolve
        page.check('Unresolve thread')
      end

      click_button(button_text)
    end

    wait_for_requests
  end
end
