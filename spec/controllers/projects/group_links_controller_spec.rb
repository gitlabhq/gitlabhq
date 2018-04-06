require 'spec_helper'

describe Projects::GroupLinksController do
  let(:group) { create(:group, :private) }
  let(:group2) { create(:group, :private) }
  let(:project) { create(:project, :private, group: group2) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)
  end

  describe '#create' do
    shared_context 'link project to group' do
      before do
        post(:create, namespace_id: project.namespace,
                      project_id: project,
                      link_group_id: group.id,
                      link_group_access: ProjectGroupLink.default_access)
      end
    end

    context 'when project is not allowed to be shared with a group' do
      before do
        group.update_attributes(share_with_group_lock: false)
      end

      include_context 'link project to group'

      it 'responds with status 404' do
        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when user has access to group he want to link project to' do
      before do
        group.add_developer(user)
      end

      include_context 'link project to group'

      it 'links project with selected group' do
        expect(group.shared_projects).to include project
      end

      it 'redirects to project group links page' do
        expect(response).to redirect_to(
          project_project_members_path(project)
        )
      end
    end

    context 'when user doers not have access to group he want to link to' do
      include_context 'link project to group'

      it 'renders 404' do
        expect(response.status).to eq 404
      end

      it 'does not share project with that group' do
        expect(group.shared_projects).not_to include project
      end
    end

    context 'when project group id equal link group id' do
      before do
        post(:create, namespace_id: project.namespace,
                      project_id: project,
                      link_group_id: group2.id,
                      link_group_access: ProjectGroupLink.default_access)
      end

      it 'does not share project with selected group' do
        expect(group2.shared_projects).not_to include project
      end

      it 'redirects to project group links page' do
        expect(response).to redirect_to(
          project_project_members_path(project)
        )
      end
    end

    context 'when link group id is not present' do
      before do
        post(:create, namespace_id: project.namespace,
                      project_id: project,
                      link_group_access: ProjectGroupLink.default_access)
      end

      it 'redirects to project group links page' do
        expect(response).to redirect_to(
          project_project_members_path(project)
        )
        expect(flash[:alert]).to eq('Please select a group.')
      end
    end
  end
end
