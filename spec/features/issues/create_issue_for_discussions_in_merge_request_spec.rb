# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Resolving all open threads in a merge request from an issue', :js, feature_category: :team_planning do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let!(:discussion) { create(:diff_note_on_merge_request, noteable: merge_request, project: project).to_discussion }

  def resolve_all_discussions_link_selector(title: "")
    url = new_project_issue_path(project, merge_request_to_resolve_discussions_of: merge_request.iid, merge_request_id: merge_request.id)

    if title.empty?
      %(a[href="#{url}"])
    else
      %(a[title="#{title}"][href="#{url}"])
    end
  end

  describe 'as a user with access to the project' do
    before do
      project.add_maintainer(user)
      sign_in user
      visit project_merge_request_path(project, merge_request)
    end

    it 'shows a button to resolve all threads by creating a new issue' do
      find('.discussions-counter .gl-new-dropdown-toggle').click

      within('.discussions-counter') do
        expect(page).to have_link(_("Resolve all with new issue"), href: new_project_issue_path(project, merge_request_to_resolve_discussions_of: merge_request.iid, merge_request_id: merge_request.id))
      end
    end

    context 'resolving the thread' do
      before do
        find('button[data-testid="resolve-discussion-button"]').click
      end

      it 'hides the link for creating a new issue' do
        expect(page).not_to have_selector resolve_all_discussions_link_selector
      end
    end

    context 'creating an issue for threads', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/420845' do
      before do
        find('.discussions-counter .gl-new-dropdown-toggle').click
        find(resolve_all_discussions_link_selector).click
      end

      it_behaves_like 'creating an issue for a thread'
    end

    context 'for a project where all threads need to be resolved before merging' do
      before do
        project.update_attribute(:only_allow_merge_if_all_discussions_are_resolved, true)
      end

      context 'with the internal tracker disabled' do
        before do
          project.project_feature.update_attribute(:issues_access_level, ProjectFeature::DISABLED)
          visit project_merge_request_path(project, merge_request)
          find('.discussions-counter .gl-new-dropdown-toggle').click
        end

        it 'does not show a link to create a new issue' do
          expect(page).not_to have_link 'Resolve all with new issue'
        end
      end

      context 'merge request has threads that need to be resolved' do
        before do
          visit project_merge_request_path(project, merge_request)
        end

        it 'shows a warning that the merge request contains unresolved threads' do
          click_button 'Expand merge checks'

          expect(page).to have_content 'Unresolved discussions must be resolved'
        end
      end
    end
  end

  describe 'as a reporter' do
    before do
      project.add_reporter(user)
      sign_in user
      visit new_project_issue_path(project, merge_request_to_resolve_discussions_of: merge_request.iid)
    end

    it 'shows a notice to ask someone else to resolve the threads' do
      expect(page).to have_content("The threads at #{merge_request.to_reference} will stay unresolved. Ask someone with permission to resolve them.")
    end
  end
end
