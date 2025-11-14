# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Resolve an open thread in a merge request by creating an issue', :js, feature_category: :team_planning do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, only_allow_merge_if_all_discussions_are_resolved: true) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let!(:discussion) { create(:diff_note_on_merge_request, noteable: merge_request, project: project).to_discussion }

  def resolve_discussion_selector
    title = 'Create issue to resolve thread'
    url = new_project_issue_path(project, discussion_to_resolve: discussion.id, merge_request_to_resolve_discussions_of: merge_request.iid, merge_request_id: merge_request.id)
    "a[title=\"#{title}\"][href=\"#{url}\"]"
  end

  describe 'As a user with access to the project' do
    before do
      project.add_maintainer(user)
      sign_in user
      visit project_merge_request_path(project, merge_request)
    end

    context 'with the internal tracker disabled' do
      before do
        project.project_feature.update_attribute(:issues_access_level, ProjectFeature::DISABLED)
        visit project_merge_request_path(project, merge_request)
      end

      # https://gitlab.com/gitlab-org/gitlab/-/issues/285453
      xit 'does not show a link to create a new issue' do
        expect(page).not_to have_css resolve_discussion_selector
      end
    end

    context 'resolving the thread' do
      it 'hides and shows the link for creating a new issue' do
        within_testid('reply-wrapper') do
          expect(page).to have_link('Create issue to resolve thread', href: new_project_issue_path(project, discussion_to_resolve: discussion.id, merge_request_to_resolve_discussions_of: merge_request.iid, merge_request_id: merge_request.id))

          click_button 'Resolve thread'

          expect(page).not_to have_link('Create issue to resolve thread', href: new_project_issue_path(project, discussion_to_resolve: discussion.id, merge_request_to_resolve_discussions_of: merge_request.iid, merge_request_id: merge_request.id))

          click_button 'Reopen thread'

          expect(page).to have_link('Create issue to resolve thread', href: new_project_issue_path(project, discussion_to_resolve: discussion.id, merge_request_to_resolve_discussions_of: merge_request.iid, merge_request_id: merge_request.id))
        end
      end
    end

    context 'creating the issue' do
      before do
        allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(200)
      end

      it 'creates an issue to resolve thread' do
        within_testid('reply-wrapper') do
          click_link('Create issue to resolve thread')
        end

        expect(find_field('Title').value).to include(merge_request.title)
        expect(find_field('Description').value).to include(discussion.first_note.note)
        expect(page).to have_text("Creating this issue will resolve the thread in !#{merge_request.iid}")

        # Actually creates an issue for the project
        expect { click_button 'Create issue' }.to change { project.issues.reload.size }.by(1)

        # Resolves the discussion in the merge request
        discussion.first_note.reload
        expect(discussion.resolved?).to be(true)

        # Issue title includes MR title
        expect(page).to have_content(%(Follow-up from "#{merge_request.title}"))
      end
    end
  end
end
