# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User comments on a diff', :js, feature_category: :code_review_workflow do
  include MergeRequestDiffHelpers
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project, target_project: project, source_branch: 'merge-test')
  end

  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit(diffs_project_merge_request_path(project, merge_request))
  end

  context 'when viewing comments' do
    context 'when toggling inline comments' do
      context 'in a single file' do
        it 'hides a comment' do
          line_element = find_by_scrolling("[id='#{sample_compare.changes[1][:line_code]}']").find(:xpath, "..")
          click_diff_line(line_element)

          page.within('.js-discussion-note-form') do
            fill_in('note_note', with: 'Line is wrong')
            click_button('Add comment now')
          end

          page.within(line_element.ancestor('[data-path]')) do
            expect(page).to have_content('Line is wrong')

            find('.js-diff-more-actions').click
            click_button 'Hide comments on this file'

            expect(page).not_to have_content('Line is wrong')
          end
        end
      end

      context 'in multiple files' do
        it 'toggles comments', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/393518' do
          first_line_element = find_by_scrolling("[id='#{sample_compare.changes[0][:line_code]}']").find(:xpath, "..")
          first_root_element = first_line_element.ancestor('[data-path]')
          click_diff_line(first_line_element)

          page.within('.js-discussion-note-form') do
            fill_in('note_note', with: 'Line is correct')
            click_button('Add comment now')
          end

          wait_for_requests

          page.within(first_root_element) do
            expect(page).to have_content('Line is correct')
          end

          second_line_element = find_by_scrolling("[id='#{sample_compare.changes[1][:line_code]}']")
          second_root_element = second_line_element.ancestor('[data-path]')

          click_diff_line(second_line_element)

          page.within('.js-discussion-note-form') do
            fill_in('note_note', with: 'Line is wrong')
            click_button('Add comment now')
          end

          wait_for_requests

          # Hide the comment.
          page.within(second_root_element) do
            find('.js-diff-more-actions').click
            click_button 'Hide comments on this file'

            expect(page).not_to have_content('Line is wrong')
          end

          # At this moment a user should see only one comment.
          # The other one should be hidden.
          page.within(first_root_element) do
            expect(page).to have_content('Line is correct')
          end

          # Show the comment.
          page.within(second_root_element) do
            find('.js-diff-more-actions').click
            click_button 'Show comments on this file'
          end

          # Now both the comments should be shown.
          page.within(second_root_element) do
            expect(page).to have_content('Line is wrong')
          end

          page.within(first_root_element) do
            expect(page).to have_content('Line is correct')
          end

          # Check the same comments in the side-by-side view.
          execute_script "window.scrollTo(0,0)"
          find('.js-show-diff-settings').click
          find_by_testid('listbox-item-parallel').click

          second_line_element = find_by_scrolling("[id='#{sample_compare.changes[1][:line_code]}']")
          second_root_element = second_line_element.ancestor('[data-path]')

          wait_for_requests

          page.within(second_root_element) do
            expect(page).to have_content('Line is wrong')
          end

          first_line_element = find_by_scrolling("[id='#{sample_compare.changes[0][:line_code]}']").find(:xpath, "..")
          first_root_element = first_line_element.ancestor('[data-path]')

          page.within(first_root_element) do
            expect(page).to have_content('Line is correct')
          end
        end
      end
    end
  end

  context 'when adding comments' do
    include_examples 'comment on merge request file'

    context 'when adding a diff suggestion in rich text editor' do
      it 'works on the Overview tab' do
        click_diff_line(find_by_scrolling("[id='#{sample_commit.line_code}']"))

        page.within('.js-discussion-note-form') do
          fill_in(:note_note, with: "```suggestion:-0+0\nchanged line\n```")
          find('.js-comment-button').click
        end

        visit(merge_request_path(merge_request))

        page.within('.notes .discussion') do
          find_by_testid('discussion-reply-tab').click
          click_button "Switch to rich text editing"
          click_button "Insert suggestion"
        end

        within_testid('content-editor') do
          expect(page).to have_content('Suggested change From line')
        end
      end
    end
  end

  context 'when adding multiline comments' do
    it 'saves a multiline comment' do
      click_diff_line(find_by_scrolling("[id='#{sample_commit.line_code}']").find(:xpath, '..'))
      add_comment('-13', '+14')
    end

    context 'when in side-by-side view' do
      before do
        visit(diffs_project_merge_request_path(project, merge_request, view: 'parallel'))
      end

      # In `files/ruby/popen.rb`
      it 'allows comments for changes involving both sides' do
        # click +15, select -13 add and verify comment
        click_diff_line(find_by_scrolling('div[data-path="files/ruby/popen.rb"] .right-side a[data-linenumber="15"]').find(:xpath, '../../..'), 'right')
        add_comment('-13', '+15')
      end

      it 'allows comments on previously hidden lines at the top of a file', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/285294' do
        # Click -9, expand up, select 1 add and verify comment
        page.within find_by_scrolling('[data-path="files/ruby/popen.rb"]') do
          all('.js-unfold-all')[0].click
        end
        click_diff_line(find('div[data-path="files/ruby/popen.rb"] .left-side a[data-linenumber="9"]').find(:xpath, '../..'), 'left')
        add_comment('1', '-9')
      end

      it 'allows comments on previously hidden lines the middle of a file' do
        # Click 27, expand up, select 18, add and verify comment
        page.within find_by_scrolling('[data-path="files/ruby/popen.rb"]') do
          first('.js-unfold-all').click
        end
        click_diff_line(find('div[data-path="files/ruby/popen.rb"] .left-side a[data-linenumber="21"]').find(:xpath, '../..'), 'left')
        add_comment('18', '21')
      end

      it 'allows comments on previously hidden lines at the bottom of a file' do
        # Click +28, expand down, select 37 add and verify comment
        page.within find_by_scrolling('[data-path="files/ruby/popen.rb"]') do
          first('.js-unfold-down').click
        end
        click_diff_line(find('div[data-path="files/ruby/popen.rb"] .left-side a[data-linenumber="30"]').find(:xpath, '../..'), 'left')
        add_comment('+28', '30')
      end
    end

    def add_comment(start_line, end_line)
      page.within('.discussion-form') do
        find('#comment-line-start option', exact_text: start_line).select_option
      end

      page.within('.js-discussion-note-form') do
        fill_in(:note_note, with: 'Line is wrong')
        click_button('Add comment now')
      end

      wait_for_requests

      page.within('.notes_holder') do
        expect(page).to have_content('Line is wrong')
        expect(page).to have_content("Comment on lines #{start_line} to #{end_line}")
      end

      visit(merge_request_path(merge_request))

      page.within('.notes .discussion') do
        expect(page).to have_content("#{user.name} #{user.to_reference} started a thread")
        expect(page).to have_content(sample_commit.line_code_path)
        expect(page).to have_content('Line is wrong')
      end

      page.within('.notes-tab .badge') do
        expect(page).to have_content('1')
      end
    end
  end

  context 'when editing comments' do
    it 'edits a comment' do
      click_diff_line(find_by_scrolling("[id='#{sample_commit.line_code}']"))

      page.within('.js-discussion-note-form') do
        fill_in(:note_note, with: 'Line is wrong')
        click_button('Add comment now')
      end

      page.within('.diff-file:nth-of-type(1) .discussion .note') do
        find('.js-note-edit').click

        page.within('.current-note-edit-form') do
          fill_in('note_note', with: 'Typo, please fix')
          click_button('Save comment')
        end

        expect(page).not_to have_button('Save comment', disabled: true)
      end

      page.within('.diff-file:nth-of-type(1) .discussion .note') do
        expect(page).to have_content('Typo, please fix').and have_no_content('Line is wrong')
      end
    end
  end

  context 'when deleting comments' do
    it 'deletes a comment' do
      click_diff_line(find_by_scrolling("[id='#{sample_commit.line_code}']"))

      page.within('.js-discussion-note-form') do
        fill_in(:note_note, with: 'Line is wrong')
        click_button('Add comment now')
      end

      page.within('.notes-tab .badge') do
        expect(page).to have_content('1')
      end

      page.within('.diff-file:nth-of-type(1) .discussion .note') do
        find('.more-actions').click
        find('.more-actions li', match: :first)
        find('.js-note-delete').click
      end

      page.within('.modal') do
        click_button('Delete comment', match: :first)
      end

      find('.notes-tab', visible: true).click

      wait_for_requests

      expect(page).not_to have_css('.notes .discussion')

      page.within('.notes-tab .badge') do
        expect(page).to have_content('0')
      end
    end
  end
end
