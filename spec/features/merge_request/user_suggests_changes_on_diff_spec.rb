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
    project.add_maintainer(user)
    sign_in(user)

    visit(diffs_project_merge_request_path(project, merge_request))
  end

  context 'single suggestion note' do
    it 'suggestion is presented' do
      click_diff_line(find("[id='#{sample_compare.changes[1][:line_code]}']"))

      page.within('.js-discussion-note-form') do
        fill_in('note_note', with: "```suggestion\n# change to a comment\n```")
        click_button('Comment')
      end

      wait_for_requests

      page.within('.diff-discussions') do
        expect(page).to have_button('Apply suggestion')
        expect(page).to have_content('Suggested change')
        expect(page).to have_content('	url = https://github.com/gitlabhq/gitlab-shell.git')
        expect(page).to have_content('# change to a comment')
      end
    end

    it 'suggestion is appliable' do
      click_diff_line(find("[id='#{sample_compare.changes[1][:line_code]}']"))

      page.within('.js-discussion-note-form') do
        fill_in('note_note', with: "```suggestion\n# change to a comment\n```")
        click_button('Comment')
      end

      wait_for_requests

      page.within('.diff-discussions') do
        expect(page).not_to have_content('Applied')

        click_button('Apply suggestion')
        wait_for_requests

        expect(page).to have_content('Applied')
      end
    end
  end

  context 'multiple suggestions in a single note' do
    it 'suggestions are presented' do
      click_diff_line(find("[id='#{sample_compare.changes[1][:line_code]}']"))

      page.within('.js-discussion-note-form') do
        fill_in('note_note', with: "```suggestion\n# change to a comment\n```\n```suggestion\n# or that\n```")
        click_button('Comment')
      end

      wait_for_requests

      page.within('.diff-discussions') do
        suggestion_1 = page.all(:css, '.md-suggestion-diff')[0]
        suggestion_2 = page.all(:css, '.md-suggestion-diff')[1]

        expect(suggestion_1).to have_content('	url = https://github.com/gitlabhq/gitlab-shell.git')
        expect(suggestion_1).to have_content('# change to a comment')

        expect(suggestion_2).to have_content('	url = https://github.com/gitlabhq/gitlab-shell.git')
        expect(suggestion_2).to have_content('# or that')
      end
    end
  end
end
