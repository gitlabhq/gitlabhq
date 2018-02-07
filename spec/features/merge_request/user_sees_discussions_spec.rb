require 'rails_helper'

describe 'Merge request > User sees discussions' do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:merge_request) { create(:merge_request, source_project: project) }

  before do
    project.add_master(user)
    sign_in(user)
  end

  describe "Diff discussions" do
    let!(:old_merge_request_diff) { merge_request.merge_request_diffs.create(diff_refs: outdated_diff_refs) }
    let!(:new_merge_request_diff) { merge_request.merge_request_diffs.create }
    let!(:outdated_discussion) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, position: outdated_position).to_discussion }
    let!(:active_discussion) { create(:diff_note_on_merge_request, noteable: merge_request, project: project).to_discussion }
    let(:outdated_position) do
      Gitlab::Diff::Position.new(
        old_path: "files/ruby/popen.rb",
        new_path: "files/ruby/popen.rb",
        old_line: nil,
        new_line: 9,
        diff_refs: outdated_diff_refs
      )
    end
    let(:outdated_diff_refs) { project.commit("874797c3a73b60d2187ed6e2fcabd289ff75171e").diff_refs }

    before do
      visit project_merge_request_path(project, merge_request)
    end

    context 'active discussions' do
      it 'shows a link to the diff' do
        within(".discussion[data-discussion-id='#{active_discussion.id}']") do
          path = diffs_project_merge_request_path(project, merge_request, anchor: active_discussion.line_code)
          expect(page).to have_link('the diff', href: path)
        end
      end
    end

    context 'outdated discussions' do
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
          click_button 'Reply...'
          fill_in 'note[note]', with: 'Test!'
          click_button 'Comment'

          expect(page).to have_css('.note', count: 2)
        end
      end
    end

    before do
      visit project_merge_request_path(project, merge_request)
    end

    context 'a regular commit comment' do
      let(:note) { create(:note_on_commit, project: project) }

      it_behaves_like 'a functional discussion'
    end

    context 'a commit diff comment' do
      let(:note) { create(:diff_note_on_commit, project: project) }

      it_behaves_like 'a functional discussion'
    end
  end
end
