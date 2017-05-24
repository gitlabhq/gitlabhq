require 'spec_helper'

feature 'Merge Request Discussions', feature: true do
  before do
    login_as :admin
  end

  context "Diff discussions" do
    let(:merge_request) { create(:merge_request, importing: true) }
    let(:project) { merge_request.source_project }
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

    before(:each) do
      visit namespace_project_merge_request_path(project.namespace, project, merge_request)
    end

    context 'active discussions' do
      it 'shows a link to the diff' do
        within(".discussion[data-discussion-id='#{active_discussion.id}']") do
          path = diffs_namespace_project_merge_request_path(project.namespace, project, merge_request, anchor: active_discussion.line_code)
          expect(page).to have_link('the diff', href: path)
        end
      end
    end

    context 'outdated discussions' do
      it 'shows a link to the outdated diff' do
        within(".discussion[data-discussion-id='#{outdated_discussion.id}']") do
          path = diffs_namespace_project_merge_request_path(project.namespace, project, merge_request, diff_id: old_merge_request_diff.id, anchor: outdated_discussion.line_code)
          expect(page).to have_link('an old version of the diff', href: path)
        end
      end
    end
  end
end
