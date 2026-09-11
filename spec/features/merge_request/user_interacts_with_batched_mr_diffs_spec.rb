# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Batch diffs', :js, feature_category: :code_review_workflow do
  include RepoHelpers
  include RapidDiffsDiscussionHelpers

  let_it_be(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project, source_branch: 'master', target_branch: 'empty-branch') }

  # Streaming keeps appending files, so the last one has to be resolved once and
  # then looked up by path: re-running the scroll can land on a different file.
  let(:second_diff_path) do
    stream_all_diffs
    all('diff-file header h2').last.text
  end

  before do
    sign_in(project.first_owner)

    visit diffs_project_merge_request_path(merge_request.project, merge_request)
    wait_for_requests

    line_holder = first_commentable_line(get_first_diff)
    click_diff_line(line_holder)

    next_discussion_row(line_holder).fill_in('note[note]', with: 'First Line Comment')
    click_button('Add comment now')

    line_holder = first_commentable_line(get_second_diff)
    click_diff_line(line_holder)

    next_discussion_row(line_holder).fill_in('note[note]', with: 'Last Line Comment')
    click_button('Add comment now')

    wait_for_requests
  end

  it 'assigns discussions to diff files across multiple batch pages' do
    # Reload so we know the discussions are persisting across batch loads
    visit page.current_url

    wait_for_requests

    # Confirm discussions are applied to appropriate files (should be contained in multiple diff pages)
    expect(get_first_diff).to have_content('First Line Comment')

    expect(get_second_diff).to have_content('Last Line Comment')
  end

  context 'when user visits a URL with a link directly to to a discussion' do
    context 'which is in the first batched page of diffs' do
      it 'scrolls to the correct discussion', skip: 'Rapid Diffs: #note_ discussion deep-link not handled by fragment loader (index.js populateLegacyFileFragment); ' \
                                                'https://gitlab.com/gitlab-org/gitlab/-/issues/628498' do
        within(get_first_diff) do
          click_link('just now')
        end

        visit page.current_url

        wait_for_requests

        # Confirm scrolled to correct UI element
        expect(find_by_testid('noteable-note-container', context: get_first_diff).obscured?).to be_falsey
      end
    end

    context 'which is in at least page 2 of the batched pages of diffs' do
      it 'scrolls to the correct discussion', skip: 'Rapid Diffs: #note_ discussion deep-link not handled by fragment loader (index.js populateLegacyFileFragment); ' \
                                                'https://gitlab.com/gitlab-org/gitlab/-/issues/628498' do
        within(get_second_diff) do
          click_link('just now')
        end

        visit page.current_url

        wait_for_requests

        stream_all_diffs

        expect(page).to have_selector('[data-testid="noteable-note-container"]', text: 'Last Line Comment', obscured: false)
        expect(page).to have_selector('[data-testid="noteable-note-container"]', text: 'First Line Comment', obscured: true)
      end
    end
  end

  context 'when user switches view styles' do
    before do
      select_parallel_view

      wait_for_requests
    end

    it 'has the correct discussions applied to files across batched pages' do
      expect(get_first_diff).to have_content('First Line Comment')

      expect(get_second_diff).to have_content('Last Line Comment')
    end
  end

  def get_first_diff
    all('diff-file').first
  end

  def get_second_diff
    diff_file(second_diff_path)
  end

  def stream_all_diffs
    previous = -1
    while (current = all('diff-file').size) != previous
      previous = current
      page.execute_script('window.scrollTo(0, document.body.scrollHeight)')
      wait_for_requests
    end
  end

  def first_commentable_line(diff_file)
    diff_file.first('[data-hunk-lines] [data-line-number]', match: :first).find(:xpath, './ancestor::tr[1]')
  end
end
