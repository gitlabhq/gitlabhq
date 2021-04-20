# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GroupLinksController do
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:group2) { create(:group, :private) }
  let_it_be(:project) { create(:project, :private, group: group2) }
  let_it_be(:user) { create(:user) }

  before do
    travel_to DateTime.new(2019, 4, 1)
    project.add_maintainer(user)
    sign_in(user)
  end

  after do
    travel_back
  end

  describe '#create' do
    shared_context 'link project to group' do
      before do
        post(:create, params: {
                        namespace_id: project.namespace,
                        project_id: project,
                        link_group_id: group.id,
                        link_group_access: ProjectGroupLink.default_access
                      })
      end
    end

    context 'when project is not allowed to be shared with a group' do
      before do
        group.update!(share_with_group_lock: false)
      end

      include_context 'link project to group'

      it 'responds with status 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user has access to group they want to link project to' do
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

    context 'when user doers not have access to group they want to link to' do
      include_context 'link project to group'

      it 'renders 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'does not share project with that group' do
        expect(group.shared_projects).not_to include project
      end
    end

    context 'when user does not have access to the public group' do
      let(:group) { create(:group, :public) }

      include_context 'link project to group'

      it 'renders 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'does not share project with that group' do
        expect(group.shared_projects).not_to include project
      end
    end

    context 'when project group id equal link group id' do
      before do
        group2.add_developer(user)

        post(:create, params: {
                        namespace_id: project.namespace,
                        project_id: project,
                        link_group_id: group2.id,
                        link_group_access: ProjectGroupLink.default_access
                      })
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
        post(:create, params: {
                        namespace_id: project.namespace,
                        project_id: project,
                        link_group_access: ProjectGroupLink.default_access
                      })
      end

      it 'redirects to project group links page' do
        expect(response).to redirect_to(
          project_project_members_path(project)
        )
        expect(flash[:alert]).to eq('Please select a group.')
      end
    end

    context 'when link is not persisted in the database' do
      before do
        allow(::Projects::GroupLinks::CreateService).to receive_message_chain(:new, :execute)
          .and_return({ status: :error, http_status: 409, message: 'error' })

        post(:create, params: {
                        namespace_id: project.namespace,
                        project_id: project,
                        link_group_id: group.id,
                        link_group_access: ProjectGroupLink.default_access
                      })
      end

      it 'redirects to project group links page' do
        expect(response).to redirect_to(
          project_project_members_path(project)
        )
        expect(flash[:alert]).to eq('error')
      end
    end
  end

  describe '#update' do
    let_it_be(:link) do
      create(
        :project_group_link,
        {
          project: project,
          group: group
        }
      )
    end

    let(:expiry_date) { 1.month.from_now.to_date }

    before do
      travel_to Time.now.utc.beginning_of_day

      put(
        :update,
        params: {
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          id: link.id,
          group_link: { group_access: Gitlab::Access::GUEST, expires_at: expiry_date }
        },
        format: :json
      )
    end

    context 'when `expires_at` is set' do
      it 'returns correct json response' do
        expect(json_response).to eq({ "expires_in" => "about 1 month", "expires_soon" => false })
      end
    end

    context 'when `expires_at` is not set' do
      let(:expiry_date) { nil }

      it 'returns empty json response' do
        expect(json_response).to be_empty
      end
    end
  end
end
