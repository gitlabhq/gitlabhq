# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Batch diffs', :js, feature_category: :code_review_workflow do
  include MergeRequestDiffHelpers
  include RepoHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, source_branch: 'master', target_branch: 'empty-branch') }

  before do
    sign_in(project.first_owner)

    visit diffs_project_merge_request_path(merge_request.project, merge_request)
    wait_for_requests

    within(get_first_diff) do
      click_diff_line(find_by_testid('left-side', match: :first))
    end

    page.within get_first_diff.find('.js-discussion-note-form') do
      fill_in('note_note', with: 'First Line Comment')
      click_button('Add comment now')
    end

    within(get_second_diff) do
      click_diff_line(find_by_testid('left-side', match: :first))
    end

    page.within get_second_diff.find('.js-discussion-note-form') do
      fill_in('note_note', with: 'Last Line Comment')
      click_button('Add comment now')
    end

    wait_for_requests
  end

  it 'assigns discussions to diff files across multiple batch pages' do
    # Reload so we know the discussions are persisting across batch loads
    visit page.current_url

    wait_for_requests

    # Confirm discussions are applied to appropriate files (should be contained in multiple diff pages)
    page.within get_first_diff.find('.notes .timeline-entry .note .note-text') do
      expect(page).to have_content('First Line Comment')
    end

    page.within get_second_diff.find('.notes .timeline-entry .note .note-text') do
      expect(page).to have_content('Last Line Comment')
    end
  end

  context 'when user visits a URL with a link directly to to a discussion' do
    context 'which is in the first batched page of diffs' do
      it 'scrolls to the correct discussion',
        quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/410029' } do
        page.within get_first_diff do
          click_link('just now')
        end

        visit page.current_url

        wait_for_requests

        # Confirm scrolled to correct UI element
        expect(get_first_diff.find('.discussion-notes .timeline-entry li.note[id]').obscured?).to be_falsey
      end
    end

    context 'which is in at least page 2 of the batched pages of diffs' do
      it 'scrolls to the correct discussion',
        quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/293814' } do
        page.within get_first_diff do
          click_link('just now')
        end

        visit page.current_url

        wait_for_requests

        # Confirm scrolled to correct UI element
        expect(get_first_diff.find('.discussion-notes .timeline-entry li.note[id]').obscured?).to be_truthy
        expect(get_second_diff.find('.discussion-notes .timeline-entry li.note[id]').obscured?).to be_falsey
      end
    end
  end

  context 'when user switches view styles' do
    before do
      find('.js-show-diff-settings').click
      find_by_testid('listbox-item-parallel').click

      wait_for_requests
    end

    it 'has the correct discussions applied to files across batched pages' do
      page.within get_first_diff.find('.notes .timeline-entry .note .note-text') do
        expect(page).to have_content('First Line Comment')
      end

      page.within get_second_diff.find('.notes .timeline-entry .note .note-text') do
        expect(page).to have_content('Last Line Comment')
      end
    end
  end

  def get_first_diff
    find('#a9b6f940524f646951cc28d954aa41f814f95d4f')
  end

  def get_second_diff
    find('#b285a86891571c7fdbf1f82e840816079de1cc8b')
  end
end
