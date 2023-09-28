# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees threads', :js, feature_category: :code_review_workflow do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:merge_request) { create(:merge_request, source_project: project) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe "Diff discussions" do
    let!(:old_merge_request_diff) { merge_request.merge_request_diffs.create!(diff_refs: outdated_diff_refs) }
    let!(:new_merge_request_diff) { merge_request.merge_request_diffs.create! }
    let!(:outdated_discussion) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, position: outdated_position).to_discussion }
    let!(:active_discussion) { create(:diff_note_on_merge_request, noteable: merge_request, project: project).to_discussion }
    let(:outdated_position) do
      build(:text_diff_position, :added,
        file: "files/ruby/popen.rb",
        new_line: 9,
        diff_refs: outdated_diff_refs
      )
    end

    let(:outdated_diff_refs) { project.commit("874797c3a73b60d2187ed6e2fcabd289ff75171e").diff_refs }

    before do
      visit project_merge_request_path(project, merge_request)
    end

    context 'active threads' do
      it 'shows a link to the diff' do
        within(".discussion[data-discussion-id='#{active_discussion.id}']") do
          path = diffs_project_merge_request_path(project, merge_request, anchor: active_discussion.line_code)
          expect(page).to have_link('the diff', href: path)
        end
      end
    end

    context 'outdated threads' do
      it 'shows a link to the outdated diff' do
        within(".discussion[data-discussion-id='#{outdated_discussion.id}']") do
          path = diffs_project_merge_request_path(project, merge_request, diff_id: old_merge_request_diff.id, anchor: outdated_discussion.line_code)
          expect(page).to have_link('an old version of the diff', href: path)
        end
      end
    end
  end

  describe 'Commit comments displayed in MR context', :js do
    shared_examples 'a functional discussion' do
      let(:discussion_id) { note.discussion_id(merge_request) }

      it 'is displayed' do
        expect(page).to have_css(".discussion[data-discussion-id='#{discussion_id}']")
      end

      it 'can be replied to' do
        within(".discussion[data-discussion-id='#{discussion_id}']") do
          find_field('Reply…').click
          fill_in 'note[note]', with: 'Test!'
          click_button 'Reply'

          expect(page).to have_css('.note', count: 2)
        end
      end
    end

    before do
      visit project_merge_request_path(project, merge_request)
    end

    # TODO: https://gitlab.com/gitlab-org/gitlab-foss/issues/48034
    # context 'a regular commit comment' do
    #   let(:note) { create(:note_on_commit, project: project) }
    #
    #   it_behaves_like 'a functional discussion'
    # end

    context 'a commit diff comment' do
      let(:note) { create(:diff_note_on_commit, project: project) }

      it_behaves_like 'a functional discussion'

      it 'displays correct header' do
        expect(page).to have_content "started a thread on commit #{note.commit_id[0...7]}"
      end
    end

    context 'a commit non-diff discussion' do
      let(:note) { create(:discussion_note_on_commit, project: project) }

      it 'displays correct header' do
        page.within(find("#note_#{note.id}", match: :first)) do
          refresh # Trigger a refresh of notes.
          wait_for_requests
          expect(page).to have_content "commented on commit #{note.commit_id[0...7]}"
        end
      end
    end
  end
end
