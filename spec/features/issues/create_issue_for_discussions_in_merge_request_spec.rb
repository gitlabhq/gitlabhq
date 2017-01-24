require 'rails_helper'

feature 'Resolving all open discussions in a merge request from an issue', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, only_allow_merge_if_all_discussions_are_resolved: true) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let!(:discussion) { Discussion.for_diff_notes([create(:diff_note_on_merge_request, noteable: merge_request, project: project)]).first }

  before do
    project.team << [user, :master]
    login_as user
  end

  context 'with the internal tracker disabled' do
    before do
      project.project_feature.update_attribute(:issues_access_level, ProjectFeature::DISABLED)
      visit namespace_project_merge_request_path(project.namespace, project, merge_request)
    end

    it 'does not show a link to create a new issue' do
      expect(page).not_to have_link 'open an issue to resolve them later'
    end
  end

  context 'merge request has discussions that need to be resolved' do
    before do
      visit namespace_project_merge_request_path(project.namespace, project, merge_request)
    end

    it 'shows a warning that the merge request contains unresolved discussions' do
      expect(page).to have_content 'This merge request has unresolved discussions'
    end

    it 'has a link to resolve all discussions by creating an issue' do
      page.within '.mr-widget-body' do
        expect(page).to have_link 'open an issue to resolve them later', href: new_namespace_project_issue_path(project.namespace, project, merge_request_for_resolving_discussions: merge_request.iid)
      end
    end

    context 'creating an issue for discussions' do
      before do
        page.click_link 'open an issue to resolve them later', href: new_namespace_project_issue_path(project.namespace, project, merge_request_for_resolving_discussions: merge_request.iid)
      end

      it 'shows an issue with the title filled in' do
        title_field = page.find_field('issue[title]')

        expect(title_field.value).to include(merge_request.title)
      end

      it 'has a mention of the discussion in the description'  do
        description_field = page.find_field('issue[description]')

        expect(description_field.value).to include(discussion.first_note.note)
      end

      it 'has a hidden field for the merge request' do
        merge_request_field = find('#merge_request_for_resolving_discussions', visible: false)

        expect(merge_request_field.value).to eq(merge_request.iid.to_s)
      end

      it 'can create a new issue for the project' do
        expect { click_button 'Submit issue' }.to change { project.issues.reload.size }.by(1)
      end

      it 'resolves the discussion in the merge request' do
        click_button 'Submit issue'

        discussion.first_note.reload

        expect(discussion.resolved?).to eq(true)
      end
    end
  end
end
