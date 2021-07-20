# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Batch diffs', :js do
  include MergeRequestDiffHelpers
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project, source_branch: 'master', target_branch: 'empty-branch') }

  before do
    sign_in(project.owner)

    visit diffs_project_merge_request_path(merge_request.project, merge_request)
    wait_for_requests

    # Add discussion to first line of first file
    click_diff_line(find('.diff-file.file-holder:first-of-type .line_holder .left-side:first-of-type'))
    page.within('.js-discussion-note-form') do
      fill_in('note_note', with: 'First Line Comment')
      click_button('Add comment now')
    end

    # Add discussion to first line of last file
    click_diff_line(find('.diff-file.file-holder:last-of-type .line_holder .left-side:first-of-type'))
    page.within('.js-discussion-note-form') do
      fill_in('note_note', with: 'Last Line Comment')
      click_button('Add comment now')
    end

    wait_for_requests
  end

  it 'assigns discussions to diff files across multiple batch pages' do
    # Reload so we know the discussions are persisting across batch loads
    visit page.current_url

    # Wait for JS to settle
    wait_for_requests

    expect(page).to have_selector('.diff-files-holder .file-holder', count: 39)

    # Confirm discussions are applied to appropriate files (should be contained in multiple diff pages)
    page.within('.diff-file.file-holder:first-of-type .notes .timeline-entry .note .note-text') do
      expect(page).to have_content('First Line Comment')
    end

    page.within('.diff-file.file-holder:last-of-type .notes .timeline-entry .note .note-text') do
      expect(page).to have_content('Last Line Comment')
    end
  end

  context 'when user visits a URL with a link directly to to a discussion' do
    context 'which is in the first batched page of diffs' do
      it 'scrolls to the correct discussion' do
        page.within('.diff-file.file-holder:first-of-type') do
          click_link('just now')
        end

        visit page.current_url

        wait_for_requests

        # Confirm scrolled to correct UI element
        expect(page.find('.diff-file.file-holder:first-of-type .discussion-notes .timeline-entry li.note[id]').obscured?).to be_falsey
        expect(page.find('.diff-file.file-holder:last-of-type .discussion-notes .timeline-entry li.note[id]').obscured?).to be_truthy
      end
    end

    context 'which is in at least page 2 of the batched pages of diffs' do
      it 'scrolls to the correct discussion',
         quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/293814' } do
        page.within('.diff-file.file-holder:last-of-type') do
          click_link('just now')
        end

        visit page.current_url

        wait_for_requests

        # Confirm scrolled to correct UI element
        expect(page.find('.diff-file.file-holder:first-of-type .discussion-notes .timeline-entry li.note[id]').obscured?).to be_truthy
        expect(page.find('.diff-file.file-holder:last-of-type .discussion-notes .timeline-entry li.note[id]').obscured?).to be_falsey
      end
    end
  end

  context 'when user switches view styles' do
    before do
      find('.js-show-diff-settings').click
      click_button 'Side-by-side'

      wait_for_requests
    end

    it 'has the correct discussions applied to files across batched pages' do
      expect(page).to have_selector('.diff-files-holder .file-holder', count: 39)

      page.within('.diff-file.file-holder:first-of-type .notes .timeline-entry .note .note-text') do
        expect(page).to have_content('First Line Comment')
      end

      page.within('.diff-file.file-holder:last-of-type .notes .timeline-entry .note .note-text') do
        expect(page).to have_content('Last Line Comment')
      end
    end
  end
end
