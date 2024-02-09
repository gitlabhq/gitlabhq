# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User comments on a diff with whitespace changes', :js, feature_category: :code_review_workflow do
  include MergeRequestDiffHelpers

  let_it_be(:project) { create(:project, :repository) }
  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project, target_project: project,
      source_branch: 'changes-with-whitespace')
  end

  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit(diffs_project_merge_request_path(project, merge_request, view: 'parallel'))
  end

  context 'when hiding whitespace changes' do
    before do
      find('.js-show-diff-settings').click
      find_by_testid('show-whitespace').click
      wait_for_requests
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
