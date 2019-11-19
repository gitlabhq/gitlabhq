# frozen_string_literal: true

require 'spec_helper'

describe 'User comments on a diff', :js do
  include MergeRequestDiffHelpers
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project, target_project: project, source_branch: 'merge-test')
  end
  let(:user) { create(:user) }

  before do
    stub_feature_flags(single_mr_diff_view: false)
    project.add_maintainer(user)
    sign_in(user)

    visit(diffs_project_merge_request_path(project, merge_request))
  end

  it_behaves_like 'rendering a single diff version'

  context 'when viewing comments' do
    context 'when toggling inline comments' do
      context 'in a single file' do
        it 'hides a comment' do
          click_diff_line(find("[id='#{sample_compare.changes[1][:line_code]}']"))

          page.within('.js-discussion-note-form') do
            fill_in('note_note', with: 'Line is wrong')
            click_button('Comment')
          end

          page.within('.diff-files-holder > div:nth-child(3)') do
            expect(page).to have_content('Line is wrong')

            find('.js-btn-vue-toggle-comments').click

            expect(page).not_to have_content('Line is wrong')
          end
        end
      end

      context 'in multiple files' do
        it 'toggles comments' do
          click_diff_line(find("[id='#{sample_compare.changes[0][:line_code]}']"))

          page.within('.js-discussion-note-form') do
            fill_in('note_note', with: 'Line is correct')
            click_button('Comment')
          end

          wait_for_requests

          page.within('.diff-files-holder > div:nth-child(2) .note-body > .note-text') do
            expect(page).to have_content('Line is correct')
          end

          click_diff_line(find("[id='#{sample_compare.changes[1][:line_code]}']"))

          page.within('.js-discussion-note-form') do
            fill_in('note_note', with: 'Line is wrong')
            click_button('Comment')
          end

          wait_for_requests

          # Hide the comment.
          page.within('.diff-files-holder > div:nth-child(3)') do
            find('.js-btn-vue-toggle-comments').click

            expect(page).not_to have_content('Line is wrong')
          end

          # At this moment a user should see only one comment.
          # The other one should be hidden.
          page.within('.diff-files-holder > div:nth-child(2) .note-body > .note-text') do
            expect(page).to have_content('Line is correct')
          end

          # Show the comment.
          page.within('.diff-files-holder > div:nth-child(3)') do
            find('.js-btn-vue-toggle-comments').click
          end

          # Now both the comments should be shown.
          page.within('.diff-files-holder > div:nth-child(3) .note-body > .note-text') do
            expect(page).to have_content('Line is wrong')
          end

          page.within('.diff-files-holder > div:nth-child(2) .note-body > .note-text') do
            expect(page).to have_content('Line is correct')
          end

          # Check the same comments in the side-by-side view.
          execute_script("window.scrollTo(0,0);")
          find('.js-show-diff-settings').click
          click_button 'Side-by-side'

          wait_for_requests

          page.within('.diff-files-holder > div:nth-child(3) .parallel .note-body > .note-text') do
            expect(page).to have_content('Line is wrong')
          end

          page.within('.diff-files-holder > div:nth-child(2) .parallel .note-body > .note-text') do
            expect(page).to have_content('Line is correct')
          end
        end
      end
    end
  end

  context 'when adding comments' do
    include_examples 'comment on merge request file'
  end

  context 'when editing comments' do
    it 'edits a comment' do
      click_diff_line(find("[id='#{sample_commit.line_code}']"))

      page.within('.js-discussion-note-form') do
        fill_in(:note_note, with: 'Line is wrong')
        click_button('Comment')
      end

      page.within('.diff-file:nth-of-type(5) .discussion .note') do
        find('.js-note-edit').click

        page.within('.current-note-edit-form') do
          fill_in('note_note', with: 'Typo, please fix')
          click_button('Save comment')
        end

        expect(page).not_to have_button('Save comment', disabled: true)
      end

      page.within('.diff-file:nth-of-type(5) .discussion .note') do
        expect(page).to have_content('Typo, please fix').and have_no_content('Line is wrong')
      end
    end
  end

  context 'when deleting comments' do
    it 'deletes a comment' do
      click_diff_line(find("[id='#{sample_commit.line_code}']"))

      page.within('.js-discussion-note-form') do
        fill_in(:note_note, with: 'Line is wrong')
        click_button('Comment')
      end

      page.within('.notes-tab .badge') do
        expect(page).to have_content('1')
      end

      page.within('.diff-file:nth-of-type(5) .discussion .note') do
        find('.more-actions').click
        find('.more-actions .dropdown-menu li', match: :first)

        accept_confirm { find('.js-note-delete').click }
      end

      page.within('.merge-request-tabs') do
        find('.notes-tab').click
      end

      wait_for_requests

      expect(page).not_to have_css('.notes .discussion')

      page.within('.notes-tab .badge') do
        expect(page).to have_content('0')
      end
    end
  end
end
