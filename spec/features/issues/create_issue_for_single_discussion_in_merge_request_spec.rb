require 'rails_helper'

feature 'Resolve an open discussion in a merge request by creating an issue' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, only_allow_merge_if_all_discussions_are_resolved: true) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let!(:discussion) { create(:diff_note_on_merge_request, noteable: merge_request, project: project).to_discussion }

  describe 'As a user with access to the project' do
    before do
      project.add_master(user)
      sign_in user
      visit project_merge_request_path(project, merge_request)
    end

    context 'with the internal tracker disabled' do
      before do
        project.project_feature.update_attribute(:issues_access_level, ProjectFeature::DISABLED)
        visit project_merge_request_path(project, merge_request)
      end

      it 'does not show a link to create a new issue' do
        expect(page).not_to have_link 'Resolve this discussion in a new issue'
      end
    end

    context 'resolving the discussion', :js do
      before do
        click_button 'Resolve discussion'
      end

      it 'hides the link for creating a new issue' do
        expect(page).not_to have_link 'Resolve this discussion in a new issue'
      end

      it 'shows the link for creating a new issue when unresolving a discussion' do
        page.within '.diff-content' do
          click_button 'Unresolve discussion'
        end

        expect(page).to have_link 'Resolve this discussion in a new issue'
      end
    end

    it 'has a link to create a new issue for a discussion' do
      new_issue_link = new_project_issue_path(project, discussion_to_resolve: discussion.id, merge_request_to_resolve_discussions_of: merge_request.iid)

      expect(page).to have_link 'Resolve this discussion in a new issue', href: new_issue_link
    end

    context 'creating the issue' do
      before do
        click_link 'Resolve this discussion in a new issue', href: new_project_issue_path(project, discussion_to_resolve: discussion.id, merge_request_to_resolve_discussions_of: merge_request.iid)
      end

      it 'has a hidden field for the discussion' do
        discussion_field = find('#discussion_to_resolve', visible: false)

        expect(discussion_field.value).to eq(discussion.id.to_s)
      end

      it_behaves_like 'creating an issue for a discussion'
    end
  end

  describe 'as a reporter' do
    before do
      project.add_reporter(user)
      sign_in user
      visit new_project_issue_path(project, merge_request_to_resolve_discussions_of: merge_request.iid,
                                            discussion_to_resolve: discussion.id)
    end

    it 'Shows a notice to ask someone else to resolve the discussions' do
      expect(page).to have_content("The discussion at #{merge_request.to_reference}"\
                                   " (discussion #{discussion.first_note.id}) will stay unresolved."\
                                   " Ask someone with permission to resolve it.")
    end
  end
end
