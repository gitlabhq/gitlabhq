# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > Batch comments', :js, feature_category: :code_review_workflow do
  include RepoHelpers
  include RapidDiffsDiscussionHelpers
  include Spec::Support::Helpers::ModalHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project, target_project: project, source_branch: 'merge-test')
  end

  before do
    project.add_maintainer(user)

    sign_in(user)
  end

  context 'on the diffs page' do
    before do
      visit_diffs
    end

    it 'adds draft note' do
      write_diff_comment

      expect(find_by_testid('draft-note')).to have_content('Line is wrong')

      expect(find_by_testid('review-drawer-toggle', match: :first)).to have_content('1')
    end

    it 'publishes review' do
      write_diff_comment

      click_button 'Your review'
      click_button 'Submit review'

      wait_for_requests

      expect(page).to have_no_testid('draft-note', text: 'Line is wrong')

      expect(page).to have_css('[data-testid="noteable-note-container"]', text: 'Line is wrong')
    end

    it 'deletes draft note' do
      write_diff_comment

      accept_gl_confirm(button_text: 'Delete comment') do
        find_by_testid('draft-note').find('[aria-label="Delete comment"]').click
      end

      wait_for_requests

      expect(page).to have_no_testid('draft-note', text: 'Line is wrong')
    end

    it 'edits draft note' do
      write_diff_comment

      draft = find_by_testid('draft-note')
      draft.find('[aria-label="Edit comment"]').click

      wait_for_requests

      within(draft) do
        fill_in('note[note]', with: 'Testing update')
        click_button('Save comment')
      end

      expect(find_by_testid('draft-note')).to have_content('Testing update')
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

        line_holder = find_line(sample_compare.changes[0][:line_code], sample_compare.changes[0][:file_path])
        click_diff_line(line_holder)
        next_discussion_row(line_holder).fill_in('note[note]', with: 'A second draft!')
        click_button('Add to review')

        expect(page).to have_text('Line is wrong')
        expect(page).to have_text('A second draft!')
      end
    end

    context 'in parallel diff' do
      before do
        select_parallel_view

        wait_for_requests
      end

      it 'adds draft comments to both sides' do
        write_parallel_comment('files/ruby/popen.rb', 'new', 9)
        write_parallel_comment('files/ruby/popen.rb', 'old', 9, button_text: 'Add to review', text: 'Another wrong line')

        expect(page).to have_css("[data-discussion-row] td:nth-child(1) [data-testid='draft-note']", text: 'Another wrong line')
        expect(page).to have_css("[data-discussion-row] td:nth-child(2) [data-testid='draft-note']", text: 'Line is wrong')

        expect(find_by_testid('review-drawer-toggle', match: :first)).to have_content('2')
      end
    end
  end

  context 'with image and file draft note' do
    let(:merge_request) { create(:merge_request_with_diffs, :with_image_diffs, source_project: project) }
    let!(:draft_on_text) { create(:draft_note_on_text_diff, merge_request: merge_request, author: user, path: 'README.md', note: 'Lorem ipsum on text...') }
    let!(:draft_on_image) { create(:draft_note_on_image_diff, merge_request: merge_request, author: user, path: 'files/images/ee_repo_logo.png', note: 'Lorem ipsum on an image...') }

    before do
      visit_overview
    end

    it 'does not show in overview' do
      expect(page).to have_no_text(draft_on_text.note)
      expect(page).to have_no_text(draft_on_image.note)
    end
  end

  context 'adding single comment to review' do
    context 'initial state' do
      before do
        visit_overview
      end

      it 'at first does not show `Add comment to review` and `Add comment now` buttons' do
        expect(page).to have_no_button('Add comment to review')
        expect(page).to have_no_button('Add comment now')
      end
    end

    context 'when review has started' do
      before do
        visit_diffs

        write_diff_comment

        visit_overview
      end

      it 'can add comment to review',
        skip: 'Rapid Diffs: thread resolution counter/timeline not reactive under useMergeRequestDiscussions store (gitlab#602723); ' \
          'https://gitlab.com/gitlab-org/gitlab/-/issues/628497' do
        write_comment(selector: '.js-main-target-form', field: 'note-body', text: 'Its a draft comment', button_text: 'Add to review')

        expect(page).to have_selector('.draft-note', text: 'Its a draft comment')

        page.within '.merge-request-tabs-container' do
          click_button 'Your review'
        end

        expect(page).to have_text('2 pending comments')
      end

      it 'can add comment right away', quarantine: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/9510' do
        write_comment(selector: '.js-main-target-form', field: 'note-body', text: 'Its a regular comment', button_text: 'Add comment now')

        expect(page).to have_selector('.note:not(.draft-note)', text: 'Its a regular comment')

        page.within '.merge-request-tabs-container' do
          click_button 'Your review'
        end

        expect(page).to have_text('1 pending comment')
      end
    end
  end

  context 'thread is unresolved' do
    let!(:active_discussion) { create(:diff_note_on_merge_request, noteable: merge_request, project: project).to_discussion }

    before do
      visit_diffs
    end

    it 'publishes comment right away and resolves the thread' do
      expect(active_discussion.resolved?).to be(false)

      write_reply_to_discussion(button_text: 'Add comment now', resolve: true)

      page.within(first('.discussions-counter')) do
        expect(page).to have_content('All threads resolved')
      end
    end

    it 'publishes review and resolves the thread' do
      expect(active_discussion.resolved?).to be(false)

      write_reply_to_discussion(resolve: true)

      click_button 'Your review'
      click_button 'Submit review'

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

      find('[data-gutter-toggle] button').click
    end

    it 'publishes comment right away and unresolves the thread',
      quarantine: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/24861' do
      expect(active_discussion.resolved?).to be(true)

      write_reply_to_discussion(button_text: 'Add comment now', unresolve: true)

      page.within(first('.discussions-counter')) do
        expect(page).to have_content('1 open thread')
      end
    end

    it 'publishes review and unresolves the thread',
      quarantine: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/24861' do
      expect(active_discussion.resolved?).to be(true)

      wait_for_requests

      write_reply_to_discussion(button_text: 'Start a review', unresolve: true)

      click_button 'Your review'
      click_button 'Submit review'

      wait_for_requests

      page.within(first('.discussions-counter')) do
        expect(page).to have_content('1 open thread')
      end
    end
  end

  def visit_diffs
    visit diffs_project_merge_request_path(merge_request.project, merge_request)

    wait_for_requests
  end

  def visit_overview
    visit project_merge_request_path(merge_request.project, merge_request)

    find('.issuable-discussion', wait: 15)
  end

  def write_diff_comment(text: 'Line is wrong', button_text: 'Start a review')
    line_holder = find_line(sample_compare.changes[0][:line_code], sample_compare.changes[0][:file_path])
    click_diff_line(line_holder)

    next_discussion_row(line_holder).fill_in('note[note]', with: text)
    click_button(button_text)

    wait_for_requests
  end

  def write_parallel_comment(file_path, side, number, button_text: 'Start a review', text: 'Line is wrong')
    retries = 0
    begin
      line_holder = line_by_number(file_path, side, number)
      click_diff_line(line_holder, side == 'old' ? 'left' : 'right')
      next_discussion_row(line_holder).fill_in('note[note]', with: text)
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      raise if (retries += 1) > 3

      retry
    end
    click_button(button_text)

    wait_for_requests
  end

  def write_comment(selector: '.js-discussion-note-form', field: 'note_note', button_text: 'Start a review', text: 'Line is wrong')
    page.within(selector) do
      fill_in(field, with: text)
      click_button(button_text)
    end

    wait_for_requests
  end

  def write_reply_to_discussion(button_text: 'Start a review', text: 'Line is wrong', resolve: false, unresolve: false)
    find_field('Reply…', match: :first).click

    fill_in('note[note]', with: text)

    if resolve
      page.check('Resolve thread')
    end

    if unresolve
      page.check('Reopen thread')
    end

    click_button(button_text)

    wait_for_requests
  end
end
