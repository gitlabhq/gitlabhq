# frozen_string_literal: true

require 'spec_helper'

describe 'User comments on a diff', :js do
  include MergeRequestDiffHelpers
  include RepoHelpers

  def expect_suggestion_has_content(element, expected_changing_content, expected_suggested_content)
    changing_content = element.all(:css, '.line_holder.old').map(&:text)
    suggested_content = element.all(:css, '.line_holder.new').map(&:text)

    expect(changing_content).to eq(expected_changing_content)
    expect(suggested_content).to eq(expected_suggested_content)
  end

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
      end

      page.within('.md-suggestion-diff') do
        expected_changing_content = [
          "6 url = https://github.com/gitlabhq/gitlab-shell.git"
        ]

        expected_suggested_content = [
          "6 # change to a comment"
        ]

        expect_suggestion_has_content(page, expected_changing_content, expected_suggested_content)
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
        fill_in('note_note', with: "```suggestion\n# change to a comment\n```\n```suggestion:-2\n# or that\n# heh\n```")
        click_button('Comment')
      end

      wait_for_requests

      page.within('.diff-discussions') do
        suggestion_1 = page.all(:css, '.md-suggestion-diff')[0]
        suggestion_2 = page.all(:css, '.md-suggestion-diff')[1]

        suggestion_1_expected_changing_content = [
          "6 url = https://github.com/gitlabhq/gitlab-shell.git"
        ]
        suggestion_1_expected_suggested_content = [
          "6 # change to a comment"
        ]

        suggestion_2_expected_changing_content = [
          "4 [submodule \"gitlab-shell\"]",
          "5 path = gitlab-shell",
          "6 url = https://github.com/gitlabhq/gitlab-shell.git"
        ]
        suggestion_2_expected_suggested_content = [
          "4 # or that",
          "5 # heh"
        ]

        expect_suggestion_has_content(suggestion_1,
                                      suggestion_1_expected_changing_content,
                                      suggestion_1_expected_suggested_content)

        expect_suggestion_has_content(suggestion_2,
                                      suggestion_2_expected_changing_content,
                                      suggestion_2_expected_suggested_content)
      end
    end
  end

  context 'multi-line suggestions' do
    before do
      click_diff_line(find("[id='#{sample_compare.changes[1][:line_code]}']"))

      page.within('.js-discussion-note-form') do
        fill_in('note_note', with: "```suggestion:-3+5\n# change to a\n# comment\n# with\n# broken\n# lines\n```")
        click_button('Comment')
      end

      wait_for_requests
    end

    it 'suggestion is presented' do
      page.within('.diff-discussions') do
        expect(page).to have_button('Apply suggestion')
        expect(page).to have_content('Suggested change')
      end

      page.within('.md-suggestion-diff') do
        expected_changing_content = [
          "3 url = git://github.com/randx/six.git",
          "4 [submodule \"gitlab-shell\"]",
          "5 path = gitlab-shell",
          "6 url = https://github.com/gitlabhq/gitlab-shell.git",
          "7 [submodule \"gitlab-grack\"]",
          "8 path = gitlab-grack",
          "9 url = https://gitlab.com/gitlab-org/gitlab-grack.git"
        ]

        expected_suggested_content = [
          "3 # change to a",
          "4 # comment",
          "5 # with",
          "6 # broken",
          "7 # lines"
        ]

        expect_suggestion_has_content(page, expected_changing_content, expected_suggested_content)
      end
    end

    it 'suggestion is appliable' do
      page.within('.diff-discussions') do
        expect(page).not_to have_content('Applied')

        click_button('Apply suggestion')
        wait_for_requests

        expect(page).to have_content('Applied')
      end
    end

    it 'resolves discussion when applied' do
      page.within('.diff-discussions') do
        expect(page).not_to have_content('Unresolve discussion')

        click_button('Apply suggestion')
        wait_for_requests

        expect(page).to have_content('Unresolve discussion')
      end
    end
  end
end
