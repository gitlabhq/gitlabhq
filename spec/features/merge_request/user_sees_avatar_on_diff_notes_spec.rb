# frozen_string_literal: true

require 'spec_helper'
include Spec::Support::Helpers::ModalHelpers # rubocop:disable  Style/MixinUsage

RSpec.describe 'Merge request > User sees avatars on diff notes', :js, feature_category: :code_review_workflow do
  include NoteInteractionHelpers
  include Spec::Support::Helpers::ModalHelpers
  include MergeRequestDiffHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user)    { project.creator }
  let_it_be(:merge_request) { create(:merge_request_with_diffs, source_project: project, author: user, title: 'Bug NS-04') }

  let(:path) { 'files/ruby/popen.rb' }
  let(:position) do
    build(:text_diff_position, :added,
      file: path,
      new_line: 9,
      diff_refs: merge_request.diff_refs
    )
  end

  let!(:note) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, position: position) }

  before_all do
    project.add_maintainer(user)
  end

  before do
    sign_in user
  end

  context 'discussion tab' do
    before do
      visit project_merge_request_path(project, merge_request)
    end

    it 'does not show avatars on discussion tab' do
      expect(page).not_to have_selector('.js-avatar-container')
      expect(page).not_to have_selector('.diff-comment-avatar-holders')
    end

    it 'does not render avatars after commenting on discussion tab' do
      find_field('Reply…').click

      page.within('.js-discussion-note-form') do
        find('.note-textarea').native.send_keys('Test comment')

        click_button 'Add comment now'
      end

      expect(page).to have_content('Test comment')
      expect(page).not_to have_selector('.js-avatar-container')
      expect(page).not_to have_selector('.diff-comment-avatar-holders')
    end
  end

  context 'commit view' do
    before do
      visit project_commit_path(project, merge_request.commits.first.id)
    end

    it 'does not render avatar after commenting' do
      first('.diff-line-num').click
      find('.js-add-diff-note-button').click

      page.within('.js-discussion-note-form') do
        find('.note-textarea').native.send_keys('test comment')

        click_button 'Comment'

        wait_for_requests
      end

      visit project_merge_request_path(project, merge_request)

      expect(page).to have_content('test comment')
      expect(page).not_to have_selector('.js-avatar-container')
      expect(page).not_to have_selector('.diff-comment-avatar-holders')
    end
  end

  %w[parallel].each do |view|
    context "#{view} view" do
      before do
        visit diffs_project_merge_request_path(project, merge_request, view: view)

        wait_for_requests

        find('.js-toggle-tree-list').click
      end

      it 'shows note avatar' do
        page.within find_line(position.line_code(project.repository)) do
          find('.diff-notes-collapse').send_keys(:return)

          expect(page).to have_selector('.js-diff-comment-avatar [data-testid="user-avatar-image"]', count: 1)
        end
      end

      it 'shows comment on note avatar' do
        page.within find_line(position.line_code(project.repository)) do
          find('.diff-notes-collapse').send_keys(:return)
          first('.js-diff-comment-avatar [data-testid="user-avatar-image"]').hover
        end

        expect(page).to have_content "#{note.author.name}: #{note.note.truncate(17)}"
      end

      it 'toggles comments when clicking avatar' do
        page.within find_line(position.line_code(project.repository)) do
          find('.diff-notes-collapse').send_keys(:return)
        end

        expect(page).not_to have_selector('.notes_holder')

        page.within find_line(position.line_code(project.repository)) do
          first('.js-diff-comment-avatar [data-testid="user-avatar-image"]').click
        end

        expect(page).to have_selector('.notes_holder')
      end

      it 'removes avatar when note is deleted' do
        open_more_actions_dropdown(note)

        accept_gl_confirm(button_text: 'Delete comment') do
          find(".note-row-#{note.id} .js-note-delete").click
        end

        wait_for_requests

        page.within find_line(position.line_code(project.repository)) do
          expect(page).not_to have_selector('.js-diff-comment-avatar [data-testid="user-avatar-image"]')
        end
      end

      it 'adds avatar when commenting' do
        find_by_scrolling('[data-discussion-id]', match: :first)
        find_field('Reply…', match: :first).click

        page.within '.js-discussion-note-form' do
          find('.js-note-text').native.send_keys('Test')

          click_button 'Add comment now'

          wait_for_requests
        end

        page.within find_line(position.line_code(project.repository)) do
          find('.diff-notes-collapse').send_keys(:return)

          expect(page).to have_selector('.js-diff-comment-avatar [data-testid="user-avatar-image"]', count: 2)
        end
      end

      it 'adds multiple comments' do
        3.times do
          find_by_scrolling('[data-discussion-id]', match: :first)
          find_field('Reply…', match: :first).click

          page.within '.js-discussion-note-form' do
            find('.js-note-text').native.send_keys('Test')
            click_button 'Add comment now'

            wait_for_requests
          end
        end

        page.within find_line(position.line_code(project.repository)) do
          find('.diff-notes-collapse').send_keys(:return)

          expect(page).to have_selector('.js-diff-comment-avatar [data-testid="user-avatar-image"]', count: 3)
          expect(find('.diff-comments-more-count')).to have_content '+1'
        end
      end

      context 'multiple comments' do
        before do
          create_list(:diff_note_on_merge_request, 3, project: project, noteable: merge_request, in_reply_to: note)
          visit diffs_project_merge_request_path(project, merge_request, view: view)

          wait_for_requests
        end

        it 'shows extra comment count' do
          page.within find_line(position.line_code(project.repository)) do
            find('.diff-notes-collapse').send_keys(:return)

            expect(find('.diff-comments-more-count')).to have_content '+1'
          end
        end
      end
    end
  end

  def find_line(line_code)
    line = find_by_scrolling("[id='#{line_code}']")
    line = line.find(:xpath, 'preceding-sibling::*[1][self::td]/preceding-sibling::*[1][self::td]') if line.tag_name == 'td'
    line
  end
end
