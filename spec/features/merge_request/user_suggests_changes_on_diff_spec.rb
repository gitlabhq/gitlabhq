# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User comments on a diff', :js, feature_category: :code_review_workflow do
  include RapidDiffsDiscussionHelpers
  include RepoHelpers

  def expect_suggestion_has_content(element, expected_changing_content, expected_suggested_content)
    changing_content = element.all(:css, '.line_holder.old').map { |el| el.text(normalize_ws: true) }
    suggested_content = element.all(:css, '.line_holder.new').map { |el| el.text(normalize_ws: true) }

    expect(changing_content).to eq(expected_changing_content)
    expect(suggested_content).to eq(expected_suggested_content)
  end

  def apply_suggestion(toggle_text: 'Apply suggestion', match: :smart)
    click_button(toggle_text, match: match)
    expect(page).to have_field('Commit message')
    find_by_testid('commit-with-custom-message-button').click
    wait_for_requests

    expand_all_collapsed_discussions
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
    wait_for_requests
  end

  context 'single suggestion note' do
    let(:file_path) { sample_compare.changes[1][:file_path] }
    let(:line_code) { sample_compare.changes[1][:line_code] }
    let(:line_holder) { find_line(line_code, file_path) }

    before do
      click_diff_line(line_holder)
    end

    it 'hides suggestion popover', skip: 'Rapid Diffs: suggestion onboarding popover not wired on the new-line comment form; ' \
                                     'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/254149' do
      expect(page).to have_selector('.diff-suggest-popover')

      find_by_testid('dismiss-suggestion-popover-button').click

      expect(page).not_to have_selector('.diff-suggest-popover')
    end

    it 'suggestion is presented' do
      next_discussion_row(line_holder).fill_in('note[note]', with: "```suggestion\n# change to a comment\n```")
      click_button('Add comment now')

      wait_for_requests

      discussion_row = next_discussion_row(line_holder)

      expect(discussion_row).to have_button('Apply suggestion')
      expect(discussion_row).to have_content('Suggested change')

      page.within(discussion_row.find('.md-suggestion-diff')) do
        expected_changing_content = [
          "6 url = https://github.com/gitlabhq/gitlab-shell.git"
        ]

        expected_suggested_content = [
          "6 # change to a comment"
        ]

        expect_suggestion_has_content(page, expected_changing_content, expected_suggested_content)
      end
    end

    it 'allows suggestions in replies', skip: 'Rapid Diffs: thread reply forms get no code suggestions config; ' \
                                          'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/254150' do
      next_discussion_row(line_holder).fill_in('note[note]', with: "```suggestion\n# change to a comment\n```")
      click_button('Add comment now')

      wait_for_requests

      find_field('Reply…', match: :first).click

      within(next_discussion_row(line_holder)) do
        click_button('Insert suggestion')
      end

      reply_field = find_field('note[note]')
      expect(reply_field.value).to include("url = https://github.com/gitlabhq/gitlab-shell.git")
    end

    it 'suggestion is appliable' do
      next_discussion_row(line_holder).fill_in('note[note]', with: "```suggestion\n# change to a comment\n```")
      click_button('Add comment now')

      wait_for_requests

      discussion_row = next_discussion_row(line_holder)

      within(discussion_row) do
        expect(page).not_to have_testid('applied-badge')

        apply_suggestion

        expect(page).to have_testid('applied-badge')
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
          path: file1,
          line_code: "#{hash(file1)}_12_12"
        },
        {
          path: file2,
          line_code: "#{hash(file2)}_21_21"
        }
      ]
    end

    before do
      files.each do |file|
        diff_file(file[:path]).find('button[aria-label="Show options"]').click
        click_button 'Show full file'
        wait_for_requests

        line_holder = find_line(file[:line_code], file[:path])
        click_diff_line(line_holder)

        next_discussion_row(line_holder).fill_in('note[note]', with: "```suggestion\n# change to a comment\n```")
        click_button('Add comment now')
        wait_for_requests
      end
    end

    it 'can add and remove suggestions from a batch' do
      files.each_with_index do |file, index|
        container = diff_file(file[:path])

        page.within(container) do
          expect(page).not_to have_content('Applied')

          click_button('Add suggestion to batch')
          wait_for_requests

          expect(page).to have_content('Remove from batch')

          if index < 1
            expect(page).to have_content("Apply suggestion")
          else
            expect(page).to have_content("Apply #{index + 1} suggestions")
          end
        end
      end

      container = diff_file(files[0][:path])
      page.within(container) do
        click_button('Remove from batch')
        wait_for_requests

        expect(page).to have_content('Add suggestion to batch')
      end

      container = diff_file(files[1][:path])
      page.within(container) do
        expect(page).to have_content('Remove from batch')
        expect(page).to have_content('Apply suggestion')
      end
    end

    it 'can apply multiple suggestions as a batch',
      quarantine: {
        issue: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/work_items/43944',
        type: :flaky
      } do
      files.each do |file|
        container = diff_file(file[:path])

        page.within(container) do
          expect(page).to have_button('Add suggestion to batch')

          click_button('Add suggestion to batch')
          wait_for_requests
        end
      end

      expect(page).not_to have_testid('applied-badge')
      expect(page).to have_button("Apply #{files.count} suggestions").twice

      container = diff_file(files[0][:path])
      page.within(container) do
        apply_suggestion(toggle_text: "Apply #{files.count} suggestions")
      end

      expand_all_collapsed_discussions
      expect(page).to have_testid('applied-badge', count: 2)
    end
  end

  context 'multiple suggestions in expanded lines' do
    it 'suggestions are appliable' do
      file_path = 'files/ruby/popen.rb'
      diff_file = merge_request.diffs(paths: [file_path]).diff_files.first
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

      diff_file(file_path).find('button[aria-label="Show options"]').click
      click_button 'Show full file'
      wait_for_requests

      line_holder = find_line(changes.first[:line_code], file_path)
      click_diff_line(line_holder)

      next_discussion_row(line_holder).fill_in('note[note]', with: "```suggestion\n# change to a comment\n```")
      click_button('Add comment now')
      wait_for_requests

      discussion_row = next_discussion_row(line_holder)
      expect(discussion_row).to have_button('Apply suggestion')
      expect(discussion_row).not_to have_button('Add suggestion to batch')

      line_holder = find_line(changes.last[:line_code], file_path)
      click_diff_line(line_holder)

      next_discussion_row(line_holder).fill_in('note[note]', with: "```suggestion\n# 2nd change to a comment\n```")
      click_button('Add comment now')
      wait_for_requests

      expect(page).to have_button('Apply suggestion').twice
      expect(page).to have_button('Add suggestion to batch').twice

      # Making sure it's not a Front-end cache.
      visit(diffs_project_merge_request_path(project, merge_request))
      wait_for_requests

      expect(page).to have_button('Apply suggestion').twice
      expect(page).to have_button('Add suggestion to batch').twice

      container = diff_file(file_path)
      page.within(container) do
        apply_suggestion(match: :first)

        expect(page).to have_testid('applied-badge', count: 1)
        expect(page).to have_button('Apply suggestion').once

        apply_suggestion

        expect(page).to have_content('A file has been changed.')
      end
    end
  end

  context 'multiple suggestions in a single note' do
    let(:file_path) { sample_compare.changes[1][:file_path] }
    let(:line_code) { sample_compare.changes[1][:line_code] }

    it 'suggestions are presented' do
      line_holder = find_line(line_code, file_path)
      click_diff_line(line_holder)

      next_discussion_row(line_holder).fill_in('note[note]', with: "```suggestion\n# change to a comment\n```\n```suggestion:-2\n# or that\n# heh\n```")
      click_button('Add comment now')

      wait_for_requests

      discussion_row = next_discussion_row(line_holder)

      expect(discussion_row).to have_css('.md-suggestion-diff', count: 2)

      suggestion_1 = discussion_row.all(:css, '.md-suggestion-diff')[0]
      suggestion_2 = discussion_row.all(:css, '.md-suggestion-diff')[1]

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

      expect_suggestion_has_content(
        suggestion_1,
        suggestion_1_expected_changing_content,
        suggestion_1_expected_suggested_content
      )

      expect_suggestion_has_content(
        suggestion_2,
        suggestion_2_expected_changing_content,
        suggestion_2_expected_suggested_content
      )
    end
  end

  context 'multi-line suggestions' do
    let(:last_change) { sample_compare.changes[1] }
    let(:line_holder) { find_line(last_change[:line_code], last_change[:file_path]) }

    before do
      click_diff_line(line_holder)

      next_discussion_row(line_holder).fill_in('note[note]', with: "```suggestion:-3+5\n# change to a\n# comment\n# with\n# broken\n# lines\n```")
      click_button('Add comment now')
      wait_for_requests
    end

    it 'suggestion is presented',
      quarantine: {
        issue: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/work_items/43944',
        type: :flaky
      } do
      within(diff_file(last_change[:file_path])) do
        expect(page).to have_button('Apply suggestion')
        expect(page).to have_content('Suggested change')

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
    end

    it 'suggestion is appliable' do
      within(diff_file(last_change[:file_path])) do
        expect(page).not_to have_testid('applied-badge')

        apply_suggestion

        expect(page).to have_testid('applied-badge')
      end
    end

    it 'resolves discussion when applied' do
      within(diff_file(last_change[:file_path])) do
        expect(page).not_to have_button('Reopen thread')

        apply_suggestion

        expect(page).to have_button('Reopen thread')
      end
    end
  end

  context 'failed to load metadata' do
    let(:file_path) { sample_compare.changes[1][:file_path] }
    let(:line_code) { sample_compare.changes[1][:line_code] }
    let(:line_holder) { find_line(line_code, file_path) }
    let(:dummy_controller) do
      Class.new(Projects::MergeRequests::DiffsController) do
        def diffs_metadata
          render json: '', status: :internal_server_error
        end
      end
    end

    before do
      stub_const('Projects::MergeRequests::DiffsController', dummy_controller)

      click_diff_line(line_holder)
      next_discussion_row(line_holder).fill_in('note[note]', with: "```suggestion\n# change to a comment\n```")
      click_button('Add comment now')
      wait_for_requests

      visit(project_merge_request_path(project, merge_request))
      wait_for_requests
    end

    it 'displays an error',
      skip: 'Rapid Diffs does not request diffs_metadata, so the warning never renders; ' \
        'https://gitlab.com/gitlab-org/gitlab/-/issues/628509' do
      within_testid('discussion-content') do
        click_button('Apply suggestion')

        expect(page).to have_content(
          'Unable to fully load the default commit message. ' \
            'You can still apply this suggestion and the commit message will be correct.'
        )
      end
    end
  end
end
