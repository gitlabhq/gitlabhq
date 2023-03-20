# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GroupLinksController, feature_category: :system_access do
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
        expect(json_response).to eq({ "expires_in" => controller.helpers.time_ago_with_tooltip(expiry_date), "expires_soon" => false })
      end
    end

    context 'when `expires_at` is not set' do
      let(:expiry_date) { nil }

      it 'returns empty json response' do
        expect(json_response).to be_empty
      end
    end
  end

  describe '#destroy' do
    let(:group_owner) { create(:user) }

    let(:link) do
      create(:project_group_link, project: project, group: group, group_access: Gitlab::Access::DEVELOPER)
    end

    subject(:destroy_link) do
      post(:destroy, params: { namespace_id: project.namespace.to_param,
                               project_id: project.to_param,
                               id: link.id })
    end

    shared_examples 'success response' do
      it 'deletes the project group link' do
        destroy_link

        expect(response).to redirect_to(project_project_members_path(project))
        expect(response).to have_gitlab_http_status(:found)
      end
    end

    context 'when user is group owner' do
      before do
        link.group.add_owner(group_owner)
        sign_in(group_owner)
      end

      context 'when user is not project maintainer' do
        it 'deletes the project group link and redirects to group show page' do
          destroy_link

          expect(response).to redirect_to(group_path(group))
          expect(response).to have_gitlab_http_status(:found)
        end
      end

      context 'when user is a project maintainer' do
        before do
          project.add_maintainer(group_owner)
        end

        it 'deletes the project group link and redirects to group show page' do
          destroy_link

          expect(response).to redirect_to(group_path(group))
          expect(response).to have_gitlab_http_status(:found)
        end
      end
    end

    context 'when user is not a group owner' do
      context 'when user is a project maintainer' do
        before do
          sign_in(user)
        end

        it_behaves_like 'success response'
      end

      context 'when user is not a project maintainer' do
        before do
          project.add_developer(user)
          sign_in(user)
        end

        it 'renders 404' do
          destroy_link

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
