# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Resolve an open thread in a merge request by creating an issue', :js, feature_category: :team_planning do
  # Ensure support bot user is created so creation doesn't count towards query limit
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/509629
  let_it_be(:support_bot) { Users::Internal.support_bot }

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
      before do
        find('button[data-testid="resolve-discussion-button"]').click
      end

      it 'hides the link for creating a new issue' do
        expect(page).not_to have_css resolve_discussion_selector
      end

      it 'shows the link for creating a new issue when unresolving a thread' do
        page.within '.diff-content' do
          click_button 'Unresolve thread'
        end

        expect(page).to have_css resolve_discussion_selector
      end
    end

    it 'has a link to create a new issue for a thread' do
      expect(page).to have_css resolve_discussion_selector
    end

    context 'creating the issue' do
      before do
        find(resolve_discussion_selector, match: :first).click
      end

      it 'has a hidden field for the thread' do
        discussion_field = find('#discussion_to_resolve', visible: false)

        expect(discussion_field.value).to eq(discussion.id.to_s)
      end

      it_behaves_like 'creating an issue for a thread'
    end
  end

  describe 'as a reporter' do
    before do
      project.add_reporter(user)
      sign_in user
      visit new_project_issue_path(
        project,
        merge_request_to_resolve_discussions_of: merge_request.iid,
        discussion_to_resolve: discussion.id
      )
    end

    it 'shows a notice to ask someone else to resolve the threads' do
      expect(page).to have_content("The thread at #{merge_request.to_reference} "\
                                   "(discussion #{discussion.first_note.id}) will stay unresolved. "\
                                   "Ask someone with permission to resolve it.")
    end
  end
end
