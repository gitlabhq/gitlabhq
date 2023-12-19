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
    let(:group_access) { Gitlab::Access::GUEST }

    subject(:update_link) do
      put(
        :update,
        params: {
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          id: link.id,
          group_link: { group_access: group_access, expires_at: expiry_date }
        },
        format: :json
      )
    end

    before do
      travel_to Time.now.utc.beginning_of_day
    end

    context 'when `expires_at` is set' do
      it 'returns correct json response' do
        update_link

        expect(json_response).to eq({ "expires_in" => controller.helpers.time_ago_with_tooltip(expiry_date), "expires_soon" => false })
      end
    end

    context 'when `expires_at` is not set' do
      let(:expiry_date) { nil }

      it 'returns empty json response' do
        update_link

        expect(json_response).to be_empty
      end
    end

    it "returns an error when link is not updated" do
      allow(::Projects::GroupLinks::UpdateService).to receive_message_chain(:new, :execute)
        .and_return(ServiceResponse.error(message: '404 Not Found', reason: :not_found))

      update_link

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Not Found')
    end

    context 'when MAINTAINER tries to update the link to OWNER access' do
      let(:group_access) { Gitlab::Access::OWNER }

      it 'returns 403' do
        update_link

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq('Forbidden')
      end
    end
  end

  describe '#destroy' do
    let(:group_owner) { create(:user) }
    let(:group_access) { Gitlab::Access::DEVELOPER }
    let(:format) { :html }

    let!(:link) do
      create(:project_group_link, project: project, group: group, group_access: group_access)
    end

    subject(:destroy_link) do
      post(:destroy, params: { namespace_id: project.namespace.to_param,
                               project_id: project.to_param,
                               id: link.id }, format: format)
    end

    shared_examples 'success response' do
      it 'deletes the project group link' do
        expect { destroy_link }.to change { project.reload.project_group_links.count }

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

        it "returns an error when link is not destroyed" do
          allow(::Projects::GroupLinks::DestroyService).to receive_message_chain(:new, :execute)
            .and_return(ServiceResponse.error(message: 'The error message'))

          expect { destroy_link }.not_to change { project.reload.project_group_links.count }
          expect(flash[:alert]).to eq('The project-group link could not be removed.')
        end

        context 'when format is js' do
          let(:format) { :js }

          it "returns an error when link is not destroyed" do
            allow(::Projects::GroupLinks::DestroyService).to receive_message_chain(:new, :execute)
              .and_return(ServiceResponse.error(message: '404 Not Found', reason: :not_found))

            expect { destroy_link }.not_to change { project.reload.project_group_links.count }
            expect(response).to have_gitlab_http_status(:not_found)
            expect(json_response['message']).to eq('404 Not Found')
          end
        end
      end

      context 'when user is not a project maintainer' do
        before do
          project.add_developer(user)
          sign_in(user)
        end

        it 'returns 404' do
          expect { destroy_link }.to not_change { project.reload.project_group_links.count }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when the user is a project maintainer' do
      before do
        project.add_maintainer(user)
        sign_in(user)
      end

      context 'when they try to destroy a link with OWNER access level' do
        let(:group_access) { Gitlab::Access::OWNER }

        it 'does not destroy the link' do
          expect { destroy_link }.to not_change { project.reload.project_group_links.count }

          expect(response).to redirect_to(project_project_members_path(project, tab: :groups))
          expect(flash[:alert]).to include('The project-group link could not be removed.')
        end

        context 'when format is js' do
          let(:format) { :js }

          it 'returns 403' do
            expect { destroy_link }.to not_change { project.reload.project_group_links.count }

            expect(json_response).to eq({ "message" => "Forbidden" })
            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end
      end
    end
  end
end
