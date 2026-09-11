# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User comments on a diff with whitespace changes', :js, feature_category: :code_review_workflow do
  include RapidDiffsDiscussionHelpers

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
        let(:line_holder) { line_by_number('files/ruby/popen.rb', 'old', 19) }

        before do
          # Comment on line combination old: 19, new 20
          # This line combination does not exist when whitespace is shown
          click_diff_line(line_holder, 'left')
          next_discussion_row(line_holder).fill_in('note[note]', with: 'Comment on diff with whitespace')
          click_button('Add comment now')

          wait_for_requests
        end

        it 'shows the comments in the diff' do
          expect(next_discussion_row(line_holder)).to have_content('Comment on diff with whitespace')
        end

        it 'allows replies to comments in the diff' do
          click_button('Reply to comment')
          fill_in('note[note]', with: 'reply to whitespace comment')
          click_button('Add comment now')
          wait_for_requests
          expect(next_discussion_row(line_holder)).to have_content('reply to whitespace comment')
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
        let(:line_holder) { line_by_number('files/ruby/popen.rb', 'old', 1) }

        before do
          click_button('Show changes')
          wait_for_requests

          click_diff_line(line_holder, 'left')
          next_discussion_row(line_holder).fill_in('note[note]', with: 'Comment on whitespace only diff')
          click_button('Add comment now')

          wait_for_requests
        end

        it 'shows the comments in the diff' do
          expect(next_discussion_row(line_holder)).to have_content('Comment on whitespace only diff')
        end

        it 'allows replies to comments in the diff' do
          click_button('Reply to comment')
          fill_in('note[note]', with: 'reply to whitespace only comment')
          click_button('Add comment now')
          wait_for_requests
          expect(next_discussion_row(line_holder)).to have_content('reply to whitespace only comment')
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
          diff_file('files/js/breadcrumbs.js').find('button[aria-label="Show options"]').click
          click_button('Show full file')
          wait_for_requests

          line_holder = line_by_number('files/js/breadcrumbs.js', 'old', 15)
          click_diff_line(line_holder, 'left')
          next_discussion_row(line_holder).fill_in('note[note]', with: 'Comment in expanded diff with whitespace')
          click_button('Add comment now')

          wait_for_requests
        end

        it 'allows editing the comment from the Overview tab',
          skip: 'Rapid Diffs: discussions store not reactive (gitlab#602723); ' \
            'https://gitlab.com/gitlab-org/gitlab/-/issues/628497' do
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
    open_diff_view_preferences
    find_by_testid('show-whitespace').click
    wait_for_requests
    close_diff_view_preferences
  end
end
