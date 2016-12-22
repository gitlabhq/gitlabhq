require 'rails_helper'

feature 'Resolve an open discussion in a merge request by creating an issue', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, only_allow_merge_if_all_discussions_are_resolved: true) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let!(:discussion) { Discussion.for_diff_notes([create(:diff_note_on_merge_request, noteable: merge_request, project: project)]).first }

  before do
    project.team << [user, :master]
    login_as user
    visit namespace_project_merge_request_path(project.namespace, project, merge_request)
  end

  context 'with the internal tracker disabled' do
    before do
      project.project_feature.update_attribute(:issues_access_level, ProjectFeature::DISABLED)
      visit namespace_project_merge_request_path(project.namespace, project, merge_request)
    end

    it 'does not show a link to create a new issue' do
      expect(page).not_to have_link 'Resolve this discussion in a new issue'
    end
  end

  context 'resolving the discussion', js: true do
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
    new_issue_link = new_namespace_project_issue_path(project.namespace, project, discussion_to_resolve: discussion.id)

    expect(page).to have_link 'Resolve this discussion in a new issue', href: new_issue_link
  end

  context 'creating the issue' do
    before do
      click_link 'Resolve this discussion in a new issue', href: new_namespace_project_issue_path(project.namespace, project, discussion_to_resolve: discussion.id)
    end

    it 'has a hidden field for the discussion' do
      discussion_field = find('#discussion_to_resolve', visible: false)

      expect(discussion_field.value).to eq(discussion.id.to_s)
    end

    it_behaves_like 'creating an issue for a discussion'
  end
end
