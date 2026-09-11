# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User comments on a diff', :js, feature_category: :code_review_workflow do
  include RepoHelpers
  include RichTextEditorHelpers
  include RapidDiffsDiscussionHelpers
  include Spec::Support::Helpers::ModalHelpers

  let(:project) { create(:project, :repository) }
  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project, target_project: project, source_branch: 'merge-test')
  end

  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit(diffs_project_merge_request_path(project, merge_request))
    wait_for_requests
  end

  context 'when viewing comments' do
    context 'when toggling inline comments' do
      context 'in a single file' do
        it 'hides a comment' do
          line_holder = find_line(sample_compare.changes[1][:line_code], sample_compare.changes[1][:file_path])
          click_diff_line(line_holder)

          discussion_row = next_discussion_row(line_holder)
          discussion_row.fill_in('note[note]', with: 'Line is wrong')
          click_button('Add comment now')

          file = diff_file(sample_compare.changes[1][:file_path])
          expect(file).to have_content('Line is wrong')

          within(file) { find_by_testid('collapse-toggle', match: :first).click }

          expect(file).not_to have_content('Line is wrong')
        end
      end

      context 'in multiple files' do
        it 'toggles comments' do
          first_line_holder = find_line(sample_compare.changes[0][:line_code], sample_compare.changes[0][:file_path])
          click_diff_line(first_line_holder)
          next_discussion_row(first_line_holder).fill_in('note[note]', with: 'Line is correct')
          click_button('Add comment now')

          wait_for_requests

          first_file = diff_file(sample_compare.changes[0][:file_path])
          expect(first_file).to have_content('Line is correct')

          second_line_holder = find_line(sample_compare.changes[1][:line_code], sample_compare.changes[1][:file_path])
          second_file = diff_file(sample_compare.changes[1][:file_path])
          click_diff_line(second_line_holder)
          next_discussion_row(second_line_holder).fill_in('note[note]', with: 'Line is wrong')
          click_button('Add comment now')

          wait_for_requests

          # Hide the comment.
          within(second_file) { find_by_testid('collapse-toggle', match: :first).click }

          expect(second_file).not_to have_content('Line is wrong')

          # At this moment a user should see only one comment.
          # The other one should be hidden.
          expect(first_file).to have_content('Line is correct')

          # Show the comment.
          within(second_file) { find_by_testid('gutter-avatar', match: :first).click }

          # Now both the comments should be shown.
          expect(second_file).to have_content('Line is wrong')
          expect(first_file).to have_content('Line is correct')

          # Check the same comments in the side-by-side view.
          select_parallel_view
          wait_for_requests

          second_file = diff_file(sample_compare.changes[1][:file_path])
          expect(second_file).to have_content('Line is wrong')

          first_file = diff_file(sample_compare.changes[0][:file_path])
          expect(first_file).to have_content('Line is correct')
        end
      end
    end
  end

  context 'when adding comments' do
    include_examples 'comment on merge request file'

    context 'when adding a diff suggestion in rich text editor' do
      it 'works on the Overview tab' do
        line_holder = find_line(sample_commit.line_code, sample_commit.line_code_path)
        click_diff_line(line_holder)

        next_discussion_row(line_holder).fill_in('note[note]', with: "```suggestion:-0+0\nchanged line\n```")
        click_button('Add comment now')

        visit(merge_request_path(merge_request))

        page.within('.notes .discussion') do
          find_by_testid('discussion-reply-tab').click
          switch_to_content_editor
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
      anchor_row = find_line(sample_commit.line_code, sample_commit.line_code_path)
      target_row = line_by_number(sample_commit.line_code_path, 'old', 13)

      drag_comment_range(anchor_row, target_row)
      submit_multiline_comment(anchor_row, target_row)
    end

    context 'when in side-by-side view' do
      before do
        visit(diffs_project_merge_request_path(project, merge_request, view: 'parallel'))
        wait_for_requests
      end

      # In `files/ruby/popen.rb`
      it 'allows comments for changes involving both sides' do
        anchor_row = line_by_number('files/ruby/popen.rb', 'new', 15)
        target_row = line_by_number('files/ruby/popen.rb', 'old', 13)

        drag_comment_range(anchor_row, target_row, 'right')
        submit_multiline_comment(anchor_row, target_row)
      end

      it 'allows comments on previously hidden lines at the top of a file' do
        expand_hunk('files/ruby/popen.rb', 'up')

        anchor_row = line_by_number('files/ruby/popen.rb', 'old', 9)
        target_row = line_by_number('files/ruby/popen.rb', 'old', 9)

        drag_comment_range(anchor_row, target_row, 'left')
        submit_multiline_comment(anchor_row, target_row)
      end

      it 'allows comments on previously hidden lines the middle of a file' do
        expand_all_context('files/ruby/popen.rb')

        anchor_row = line_by_number('files/ruby/popen.rb', 'old', 21)
        target_row = line_by_number('files/ruby/popen.rb', 'old', 18)

        drag_comment_range(anchor_row, target_row, 'left')
        submit_multiline_comment(anchor_row, target_row)
      end

      it 'allows comments on previously hidden lines at the bottom of a file',
        skip: 'Rapid Diffs: multiline cross-side drag selection is flaky under synthetic drag events; ' \
          'https://gitlab.com/gitlab-org/gitlab/-/issues/628503' do
        expand_all_context('files/ruby/popen.rb')

        anchor_row = line_by_number('files/ruby/popen.rb', 'old', 30)
        target_row = line_by_number('files/ruby/popen.rb', 'new', 28)

        drag_comment_range(anchor_row, target_row, 'left')
        submit_multiline_comment(anchor_row, target_row)
      end
    end

    def submit_multiline_comment(anchor_row, target_row)
      discussion_row = discussion_row_after_drag(anchor_row, target_row)
      discussion_row.fill_in('note[note]', with: 'Line is wrong')
      click_button('Add comment now')

      wait_for_requests

      expect(discussion_row_after_drag(anchor_row, target_row)).to have_content('Line is wrong')

      visit(merge_request_path(merge_request))

      page.within('.notes .discussion') do
        expect(page).to have_content("#{user.name} #{user.to_reference} started a thread")
        expect(page).to have_content(sample_commit.line_code_path)
        expect(page).to have_content('Line is wrong')
      end

      within_testid('notes-tab') do
        expect(page).to have_content('1')
      end
    end
  end

  context 'when editing comments' do
    it 'edits a comment' do
      line_holder = find_line(sample_commit.line_code, sample_commit.line_code_path)
      click_diff_line(line_holder)

      discussion_row = next_discussion_row(line_holder)
      discussion_row.fill_in('note[note]', with: 'Line is wrong')
      click_button('Add comment now')

      within(discussion_row) do
        find('[aria-label="Edit comment"]').click
        fill_in('note[note]', with: 'Typo, please fix')
        click_button('Save comment')

        expect(page).not_to have_button('Save comment', disabled: true)
      end

      expect(discussion_row).to have_content('Typo, please fix').and have_no_content('Line is wrong')
    end
  end

  context 'when deleting comments' do
    it 'deletes a comment' do
      line_holder = find_line(sample_commit.line_code, sample_commit.line_code_path)
      click_diff_line(line_holder)

      discussion_row = next_discussion_row(line_holder)
      discussion_row.fill_in('note[note]', with: 'Line is wrong')
      click_button('Add comment now')

      within_testid('notes-tab') do
        expect(page).to have_content('1')
      end

      accept_gl_confirm(button_text: 'Delete comment') do
        within(discussion_row) do
          find('[title="More actions"] button', match: :first).click
          click_button 'Delete comment'
        end
      end

      wait_for_requests

      find_by_testid('notes-tab', visible: true).click

      wait_for_requests

      expect(page).not_to have_css('.notes .discussion')

      within_testid('notes-tab') do
        expect(page).to have_content('0')
      end
    end
  end

  def expand_hunk(file_path, direction)
    diff_file(file_path).first("button[data-expand-direction='#{direction}']").click
    wait_for_requests
  end

  def expand_all_context(file_path)
    until diff_file(file_path).all('button[data-expand-direction]', wait: 0.5).empty?
      diff_file(file_path).first('button[data-expand-direction]').click
      wait_for_requests
    end
  end
end
