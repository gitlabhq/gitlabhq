require 'spec_helper'

feature 'Collapse outdated diff comments', js: true do
  let(:merge_request) { create(:merge_request, importing: true) }
  let(:project) { merge_request.source_project }

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
    sign_in(create(:admin))
  end

  context 'when project.collapse_outdated_diff_comments == true' do
    before do
      project.update_column(:collapse_outdated_diff_comments, true)
    end

    context 'with unresolved outdated discussions' do
      it 'does not show outdated discussion' do
        visit_merge_request(merge_request)
        within(".discussion[data-discussion-id='#{outdated_discussion.id}']") do
          expect(page).to have_css('.discussion-body .hide .js-toggle-content', visible: false)
        end
      end
    end

    context 'with unresolved active discussions' do
      it 'shows active discussion' do
        visit_merge_request(merge_request)
        within(".discussion[data-discussion-id='#{active_discussion.id}']") do
          expect(page).to have_css('.discussion-body .hide .js-toggle-content', visible: true)
        end
      end
    end
  end

  context 'when project.collapse_outdated_diff_comments == false' do
    before do
      project.update_column(:collapse_outdated_diff_comments, false)
    end

    context 'with unresolved outdated discussions' do
      it 'shows outdated discussion' do
        visit_merge_request(merge_request)
        within(".discussion[data-discussion-id='#{outdated_discussion.id}']") do
          expect(page).to have_css('.discussion-body .hide .js-toggle-content', visible: true)
        end
      end
    end

    context 'with unresolved active discussions' do
      it 'shows active discussion' do
        visit_merge_request(merge_request)
        within(".discussion[data-discussion-id='#{active_discussion.id}']") do
          expect(page).to have_css('.discussion-body .hide .js-toggle-content', visible: true)
        end
      end
    end
  end
  def visit_merge_request(merge_request)
    visit project_merge_request_path(project, merge_request)
  end
end
