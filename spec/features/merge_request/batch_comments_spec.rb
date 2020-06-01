# frozen_string_literal: true

require 'spec_helper'

describe 'Merge request > Batch comments', :js do
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
  end

  context 'Feature is enabled' do
    before do
      stub_feature_flags(diffs_batch_load: false)

      visit_diffs
    end

    it 'has review bar' do
      expect(page).to have_css('.review-bar-component', visible: false)
    end

    it 'adds draft note' do
      write_comment

      expect(find('.draft-note-component')).to have_content('Line is wrong')

      expect(page).to have_css('.review-bar-component')

      expect(find('.review-bar-content .btn-success')).to have_content('1')
    end

    it 'publishes review' do
      write_comment

      page.within('.review-bar-content') do
        click_button 'Finish review'
        click_button 'Submit review'
      end

      wait_for_requests

      expect(page).not_to have_selector('.draft-note-component', text: 'Line is wrong')

      expect(page).to have_selector('.note:not(.draft-note)', text: 'Line is wrong')
    end

    it 'publishes single comment' do
      write_comment

      click_button 'Add comment now'

      wait_for_requests

      expect(page).not_to have_selector('.draft-note-component', text: 'Line is wrong')

      expect(page).to have_selector('.note:not(.draft-note)', text: 'Line is wrong')
    end

    it 'discards review' do
      write_comment

      click_button 'Discard review'

      click_button 'Delete all pending comments'

      wait_for_requests

      expect(page).not_to have_selector('.draft-note-component')
    end

    it 'deletes draft note' do
      write_comment

      accept_alert { find('.js-note-delete').click }

      wait_for_requests

      expect(page).not_to have_selector('.draft-note-component', text: 'Line is wrong')
    end

    it 'edits draft note' do
      write_comment

      find('.js-note-edit').click

      # make sure comment form is in view
      execute_script("window.scrollBy(0, 200)")

      page.within('.js-discussion-note-form') do
        fill_in('note_note', with: 'Testing update')
        click_button('Save comment')
      end

      wait_for_requests

      expect(page).to have_selector('.draft-note-component', text: 'Testing update')
    end

    context 'in parallel diff' do
      before do
        find('.js-show-diff-settings').click
        click_button 'Side-by-side'
      end

      it 'adds draft comments to both sides' do
        write_parallel_comment('2f6fcd96b88b36ce98c38da085c795a27d92a3dd_10_9')

        # make sure line 9 is in the view
        execute_script("window.scrollBy(0, -200)")

        write_parallel_comment('2f6fcd96b88b36ce98c38da085c795a27d92a3dd_9_9', button_text: 'Add to review', text: 'Another wrong line')

        expect(find('.new .draft-note-component')).to have_content('Line is wrong')
        expect(find('.old .draft-note-component')).to have_content('Another wrong line')

        expect(find('.review-bar-content .btn-success')).to have_content('2')
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

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('All threads resolved')
          expect(page).to have_selector('.line-resolve-btn.is-active')
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

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('All threads resolved')
          expect(page).to have_selector('.line-resolve-btn.is-active')
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

      it 'publishes comment right away and unresolves the thread' do
        expect(active_discussion.resolved?).to eq(true)

        write_reply_to_discussion(button_text: 'Add comment now', unresolve: true)

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('1 unresolved thread')
          expect(page).not_to have_selector('.line-resolve-btn.is-active')
        end
      end

      it 'publishes review and unresolves the thread' do
        expect(active_discussion.resolved?).to eq(true)

        wait_for_requests

        write_reply_to_discussion(button_text: 'Start a review', unresolve: true)

        page.within('.review-bar-content') do
          click_button 'Finish review'
          click_button 'Submit review'
        end

        wait_for_requests

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('1 unresolved thread')
          expect(page).not_to have_selector('.line-resolve-btn.is-active')
        end
      end
    end
  end

  def visit_diffs
    visit diffs_project_merge_request_path(merge_request.project, merge_request)

    wait_for_requests
  end

  def write_comment(button_text: 'Start a review', text: 'Line is wrong')
    click_diff_line(find("[id='#{sample_compare.changes[0][:line_code]}']"))

    page.within('.js-discussion-note-form') do
      fill_in('note_note', with: text)
      click_button(button_text)
    end

    wait_for_requests
  end

  def write_parallel_comment(line, button_text: 'Start a review', text: 'Line is wrong')
    find("td[id='#{line}']").hover
    find(".is-over button").click

    page.within("form[data-line-code='#{line}']") do
      fill_in('note_note', with: text)
      click_button(button_text)
    end

    wait_for_requests
  end
end

def write_reply_to_discussion(button_text: 'Start a review', text: 'Line is wrong', resolve: false, unresolve: false)
  page.within(first('.diff-files-holder .discussion-reply-holder')) do
    click_button('Reply...')

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
