# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User comments on a diff with whitespace changes', :js, feature_category: :code_review_workflow do
  include MergeRequestDiffHelpers

  let_it_be(:project) { create(:project, :repository) }

  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'when MR contains a whitespace diff which contains line combinations that are not present in the real diff' do
    let(:merge_request) do
      create(:merge_request_with_diffs, source_project: project, target_project: project,
        source_branch: 'changes-with-whitespace')
    end

    before do
      visit(diffs_project_merge_request_path(project, merge_request, view: 'parallel'))
    end

    context 'when hiding whitespace changes' do
      before do
        hide_whitespace
      end

      context 'when commenting on line combinations that are not present in the real diff' do
        before do
          # Comment on line combination old: 19, new 20
          # This line combination does not exist when whitespace is shown
          click_diff_line(
            find_by_scrolling('div[data-path="files/ruby/popen.rb"] .left-side a[data-linenumber="19"]').find(:xpath,
              '../..'), 'left')
          page.within('.js-discussion-note-form') do
            fill_in(:note_note, with: 'Comment on diff with whitespace')
            click_button('Add comment now')
          end

          wait_for_requests
        end

        it 'shows the comments in the diff' do
          page.within('.notes_holder') do
            expect(page).to have_content('Comment on diff with whitespace')
          end
        end

        it 'allows replies to comments in the diff' do
          click_button('Reply to comment')
          fill_in(:note_note, with: 'reply to whitespace comment')
          click_button('Add comment now')
          wait_for_requests
          page.within('.notes_holder') do
            expect(page).to have_content('reply to whitespace comment')
          end
        end
      end
    end
  end

  context 'when the MR contains a diff with a file with whitespace changes only' do
    let(:merge_request) do
      create(:merge_request_with_diffs, source_project: project, target_project: project, target_branch: 'master',
        source_branch: 'changes-with-only-whitespace')
    end

    before do
      visit(diffs_project_merge_request_path(project, merge_request, view: 'parallel'))
    end

    context 'when hiding whitespace changes' do
      before do
        hide_whitespace
      end

      context 'when showing changes and commenting' do
        before do
          click_button('Show changes')
          wait_for_requests

          click_diff_line(
            find_by_scrolling('div[data-path="files/ruby/popen.rb"] .left-side a[data-linenumber="1"]').find(:xpath,
              '../..'), 'left')
          page.within('.js-discussion-note-form') do
            fill_in(:note_note, with: 'Comment on whitespace only diff')
            click_button('Add comment now')
          end

          wait_for_requests
        end

        it 'shows the comments in the diff' do
          page.within('.notes_holder') do
            expect(page).to have_content('Comment on whitespace only diff')
          end
        end

        it 'allows replies to comments in the diff' do
          click_button('Reply to comment')
          fill_in(:note_note, with: 'reply to whitespace only comment')
          click_button('Add comment now')
          wait_for_requests
          page.within('.notes_holder') do
            expect(page).to have_content('reply to whitespace only comment')
          end
        end
      end
    end
  end

  context 'when MR contains whitespace changes which affect collapsed lines' do
    let(:merge_request) do
      create(:merge_request_with_diffs, source_project: project, target_project: project,
        target_branch: 'expanded-whitespace-target', source_branch: 'expanded-whitespace-source')
    end

    before do
      visit(diffs_project_merge_request_path(project, merge_request, view: 'parallel'))
    end

    context 'when hiding whitespace changes' do
      before do
        hide_whitespace
      end

      context 'when commenting on collapsed line combinations that are not present in the real diff' do
        before do
          find_all('[aria-label="Expand all lines"]').first.click

          click_diff_line(
            find_by_scrolling('div[data-path="files/js/breadcrumbs.js"] .left-side a[data-linenumber="15"]')
              .find(:xpath, '../..'), 'left')
          page.within('.js-discussion-note-form') do
            fill_in(:note_note, with: 'Comment in expanded diff with whitespace')
            click_button('Add comment now')
          end

          wait_for_requests
        end

        it 'allows editing the comment from the Overview tab' do
          visit(merge_request_path(merge_request))
          click_button('Edit comment')
          fill_in(:note_note, with: 'edit whitespace comment')
          click_button('Save comment')
          wait_for_requests
          page.within('.notes_holder') do
            expect(page).to have_content('edit whitespace comment')
          end
        end
      end
    end
  end

  def hide_whitespace
    find('.js-show-diff-settings').click
    find_by_testid('show-whitespace').click
    wait_for_requests
  end
end
