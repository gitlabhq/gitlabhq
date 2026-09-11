# frozen_string_literal: true

require 'spec_helper'
include Spec::Support::Helpers::ModalHelpers # rubocop:disable  Style/MixinUsage

RSpec.describe 'Merge request > User sees avatars on diff notes', :js, feature_category: :code_review_workflow do
  include NoteInteractionHelpers
  include Spec::Support::Helpers::ModalHelpers
  include RapidDiffsHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user)    { project.creator }
  let_it_be(:merge_request, freeze: false) do
    create(:merge_request_with_diffs, source_project: project, author: user, title: 'Bug NS-04')
  end

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
    # A diff note left on a commit that belongs to the merge request shows up in the
    # MR discussion, but must not produce the diff-avatar UI that MR diff notes do.
    # (Creating notes through the Rapid Diffs commit page is covered by
    # spec/features/projects/commit/comments/*.) We use a regular feature-branch
    # merge request here because merge_request_with_diffs' head is a merge commit with
    # degenerate diff refs, which can't carry a valid commit diff note position.
    let_it_be(:commit_merge_request) do
      create(:merge_request, source_project: project, source_branch: 'feature', target_branch: 'master')
    end

    let(:commit) { project.commit('feature') }
    let(:commit_diff_file) { commit.diffs.diff_files.find { |file| file.text? && file.diff_lines.any?(&:added?) } }
    let(:commit_position) do
      build(:text_diff_position, :added,
        file: commit_diff_file.new_path,
        new_line: commit_diff_file.diff_lines.find(&:added?).new_pos,
        diff_refs: commit.diff_refs
      )
    end

    let!(:commit_diff_note) do
      create(:diff_note_on_commit, project: project, commit_id: commit.id, position: commit_position, note: 'test comment')
    end

    it 'does not render an avatar for a commit diff note', :aggregate_failures do
      visit project_merge_request_path(project, commit_merge_request)

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
      end

      it 'shows note avatar' do
        collapse_thread

        expect(commented_file).to have_selector('[data-testid="gutter-avatar"]', count: 1)
      end

      it 'shows comment on note avatar' do
        collapse_thread
        find_by_testid('gutter-avatar', context: commented_file, match: :first).hover

        expect(page).to have_content "#{note.author.name}: #{note.note.truncate(17)}"
      end

      it 'toggles comments when clicking avatar' do
        collapse_thread

        expect(commented_file).to have_selector('[data-testid="gutter-avatar"]')
        expect(commented_file).to have_no_selector('[data-testid="noteable-note-container"]')

        find_by_testid('gutter-avatar', context: commented_file, match: :first).click

        expect(commented_file).to have_selector('[data-testid="noteable-note-container"]')
      end

      it 'removes avatar when note is deleted' do
        note = find_by_testid('noteable-note-container', context: commented_file, match: :first)
        note.hover
        find_by_testid('ellipsis_v-icon', context: note, match: :first).ancestor('button').click

        accept_gl_confirm(button_text: 'Delete comment') do
          click_button 'Delete comment'
        end

        wait_for_requests

        expect(commented_file).to have_no_selector('[data-gutter-toggle]')
      end

      it 'adds avatar when commenting' do
        reply_to_thread('Test')
        collapse_thread

        expect(commented_file).to have_selector('[data-testid="gutter-avatar"]', count: 2)
      end

      it 'adds multiple comments' do
        3.times { reply_to_thread('Test') }
        collapse_thread

        expect(commented_file).to have_selector('[data-testid="gutter-avatar"]', count: 3)
        expect(commented_file).to have_selector('[data-testid="more-count"]', text: '+1')
      end

      context 'multiple comments' do
        before do
          create_list(:diff_note_on_merge_request, 3, project: project, noteable: merge_request, in_reply_to: note)
          visit diffs_project_merge_request_path(project, merge_request, view: view)

          wait_for_requests
        end

        it 'shows extra comment count' do
          collapse_thread

          expect(commented_file).to have_selector('[data-testid="more-count"]', text: '+1')
        end
      end
    end
  end

  def commented_file
    diff_file(path)
  end

  def collapse_thread
    within(commented_file) { find_by_testid('collapse-toggle', match: :first).click }
  end

  def reply_to_thread(body)
    within(commented_file) do
      find_by_testid('discussion-reply-tab').click
      find_by_testid('reply-field').set(body)
      find_by_testid('reply-comment-button').click
    end
    wait_for_requests
  end
end
