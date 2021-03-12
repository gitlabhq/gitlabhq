# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User comments on a diff', :js do
  include MergeRequestDiffHelpers
  include RepoHelpers

  def expect_suggestion_has_content(element, expected_changing_content, expected_suggested_content)
    changing_content = element.all(:css, '.line_holder.old').map { |el| el.text(normalize_ws: true) }
    suggested_content = element.all(:css, '.line_holder.new').map { |el| el.text(normalize_ws: true) }

    expect(changing_content).to eq(expected_changing_content)
    expect(suggested_content).to eq(expected_suggested_content)
  end

  def expect_appliable_suggestions(amount)
    expect(all('button', text: 'Apply suggestion').size).to eq(amount)
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
    it 'hides suggestion popover' do
      click_diff_line(find("[id='#{sample_compare.changes[1][:line_code]}']"))

      expect(page).to have_selector('.diff-suggest-popover')

      page.within('.diff-suggest-popover') do
        click_button 'Got it'
      end

      expect(page).not_to have_selector('.diff-suggest-popover')
    end

    it 'suggestion is presented' do
      click_diff_line(find("[id='#{sample_compare.changes[1][:line_code]}']"))

      page.within('.js-discussion-note-form') do
        fill_in('note_note', with: "```suggestion\n# change to a comment\n```")
        click_button('Add comment now')
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

    it 'allows suggestions in replies' do
      click_diff_line(find("[id='#{sample_compare.changes[1][:line_code]}']"))

      page.within('.js-discussion-note-form') do
        fill_in('note_note', with: "```suggestion\n# change to a comment\n```")
        click_button('Add comment now')
      end

      wait_for_requests

      find_field('Reply…', match: :first).click

      find('.js-suggestion-btn').click

      expect(find('.js-vue-issue-note-form').value).to include("url = https://github.com/gitlabhq/gitlab-shell.git")
    end

    it 'suggestion is appliable' do
      click_diff_line(find("[id='#{sample_compare.changes[1][:line_code]}']"))

      page.within('.js-discussion-note-form') do
        fill_in('note_note', with: "```suggestion\n# change to a comment\n```")
        click_button('Add comment now')
      end

      wait_for_requests

      page.within('.diff-discussions') do
        expect(page).not_to have_content('Applied')

        click_button('Apply suggestion')
        click_button('Apply')
        wait_for_requests

        expect(page).to have_content('Applied')
      end
    end
  end

  context 'applying suggestions in batches' do
    def hash(path)
      diff_file = merge_request.diffs(paths: [path]).diff_files.first
      Digest::SHA1.hexdigest(diff_file.file_path)
    end

    file1 = 'files/ruby/popen.rb'
    file2 = 'files/ruby/regex.rb'

    let(:files) do
      [
        {
          hash: hash(file1),
          line_code: "#{hash(file1)}_12_12"
        },
        {
          hash: hash(file2),
          line_code: "#{hash(file2)}_21_21"
        }
      ]
    end

    it 'can add and remove suggestions from a batch' do
      files.each_with_index do |file, index|
        page.within("[id='#{file[:hash]}']") do
          find('.js-diff-more-actions').click
          click_button 'Show full file'
          wait_for_requests

          click_diff_line(find("[id='#{file[:line_code]}']"))

          page.within('.js-discussion-note-form') do
            fill_in('note_note', with: "```suggestion\n# change to a comment\n```")
            click_button('Add comment now')
            wait_for_requests
          end
        end
      end

      files.each_with_index do |file, index|
        page.within("[id='#{file[:hash]}']") do
          expect(page).not_to have_content('Applied')

          click_button('Add suggestion to batch')
          wait_for_requests

          expect(page).to have_content('Remove from batch')
          expect(page).to have_content("Apply suggestions #{index + 1}")
        end
      end

      page.within("[id='#{files[0][:hash]}']") do
        click_button('Remove from batch')
        wait_for_requests

        expect(page).to have_content('Apply suggestion')
        expect(page).to have_content('Add suggestion to batch')
      end

      page.within("[id='#{files[1][:hash]}']") do
        expect(page).to have_content('Remove from batch')
        expect(page).to have_content('Apply suggestions 1')
      end
    end

    it 'can apply multiple suggestions as a batch', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/224100' do
      files.each_with_index do |file, index|
        page.within("[id='#{file[:hash]}']") do
          find("button[title='Show full file']").click
          wait_for_requests

          click_diff_line(find("[id='#{file[:line_code]}']"))

          page.within('.js-discussion-note-form') do
            fill_in('note_note', with: "```suggestion\n# change to a comment\n```")
            click_button('Add comment now')
            wait_for_requests
          end
        end

        page.within("[id='#{file[:hash]}']") do
          click_button('Add suggestion to batch')
          wait_for_requests
        end
      end

      expect(page).not_to have_content('Applied')

      page.within("[id='#{files[0][:hash]}']") do
        click_button('Apply suggestions 2')
        wait_for_requests
      end

      expect(page).to have_content('Applied').twice
    end
  end

  context 'multiple suggestions in expanded lines' do
    it 'suggestions are appliable', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/38277' do
      diff_file = merge_request.diffs(paths: ['files/ruby/popen.rb']).diff_files.first
      hash = Digest::SHA1.hexdigest(diff_file.file_path)

      expanded_changes = [
        {
          line_code: "#{hash}_1_1",
          file_path: diff_file.file_path
        },
        {
          line_code: "#{hash}_5_5",
          file_path: diff_file.file_path
        }
      ]
      changes = sample_compare(expanded_changes).changes.last(expanded_changes.size)

      page.within("[id='#{hash}']") do
        find("button[title='Show full file']").click
        wait_for_requests

        click_diff_line(find("[id='#{changes.first[:line_code]}']"))

        page.within('.js-discussion-note-form') do
          fill_in('note_note', with: "```suggestion\n# change to a comment\n```")
          click_button('Add comment now')
          wait_for_requests
        end

        click_diff_line(find("[id='#{changes.last[:line_code]}']"))

        page.within('.js-discussion-note-form') do
          fill_in('note_note', with: "```suggestion\n# 2nd change to a comment\n```")
          click_button('Add comment now')
          wait_for_requests
        end

        expect_appliable_suggestions(2)
      end

      # Making sure it's not a Front-end cache.
      visit(diffs_project_merge_request_path(project, merge_request))

      page.within '.line-resolve-all-container' do
        page.find('.discussion-next-btn').click
      end

      expect_appliable_suggestions(2)

      page.within("[id='#{hash}']") do
        all('button', text: 'Apply suggestion').last.click
        wait_for_requests

        expect(page).to have_content('Applied')
      end
    end
  end

  context 'multiple suggestions in a single note' do
    it 'suggestions are presented', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/258989' do
      click_diff_line(find("[id='#{sample_compare.changes[1][:line_code]}']"))

      page.within('.js-discussion-note-form') do
        fill_in('note_note', with: "```suggestion\n# change to a comment\n```\n```suggestion:-2\n# or that\n# heh\n```")
        click_button('Add comment now')
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
        click_button('Add comment now')
      end

      wait_for_requests
    end

    it 'suggestion is presented', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/268240' do
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
        click_button('Apply')
        wait_for_requests

        expect(page).to have_content('Applied')
      end
    end

    it 'resolves discussion when applied' do
      page.within('.diff-discussions') do
        expect(page).not_to have_content('Unresolve thread')

        click_button('Apply suggestion')
        click_button('Apply')
        wait_for_requests

        expect(page).to have_content('Unresolve thread')
      end
    end
  end
end
