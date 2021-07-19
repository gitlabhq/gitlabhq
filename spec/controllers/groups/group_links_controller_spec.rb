# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::GroupLinksController do
  let(:shared_with_group) { create(:group, :private) }
  let(:shared_group) { create(:group, :private) }
  let(:user) { create(:user) }
  let(:group_member) { create(:user) }
  let!(:project) { create(:project, group: shared_group) }

  before do
    travel_to DateTime.new(2019, 4, 1)
    sign_in(user)

    shared_with_group.add_developer(group_member)
  end

  after do
    travel_back
  end

  shared_examples 'placeholder is passed as `id` parameter' do |action|
    it 'returns a 404' do
      post(
        action,
        params: {
          group_id: shared_group,
          id: ':id'
        },
        format: :json
      )

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe '#create' do
    let(:shared_with_group_id) { shared_with_group.id }
    let(:shared_group_access) { GroupGroupLink.default_access }

    subject do
      post(:create,
           params: { group_id: shared_group,
                     shared_with_group_id: shared_with_group_id,
                     shared_group_access: shared_group_access })
    end

    shared_examples 'creates group group link' do
      it 'links group with selected group' do
        expect { subject }.to change { shared_with_group.shared_groups.include?(shared_group) }.from(false).to(true)
      end

      it 'redirects to group links page' do
        subject

        expect(response).to(redirect_to(group_group_members_path(shared_group)))
      end

      it 'allows access for group member' do
        expect { subject }.to(
          change { group_member.can?(:read_group, shared_group) }.from(false).to(true))
      end
    end

    context 'when user has correct access to both groups' do
      before do
        shared_with_group.add_developer(user)
        shared_group.add_owner(user)
      end

      context 'when default access level is requested' do
        include_examples 'creates group group link'
      end

      context 'when owner access is requested' do
        let(:shared_group_access) { Gitlab::Access::OWNER }

        before do
          shared_with_group.add_owner(group_member)
        end

        include_examples 'creates group group link'

        it 'allows admin access for group member' do
          expect { subject }.to(
            change { group_member.can?(:admin_group, shared_group) }.from(false).to(true))
        end
      end

      it 'updates project permissions', :sidekiq_inline do
        expect { subject }.to change { group_member.can?(:read_project, project) }.from(false).to(true)
      end

      context 'when shared with group id is not present' do
        let(:shared_with_group_id) { nil }

        it 'redirects to group links page' do
          subject

          expect(response).to(redirect_to(group_group_members_path(shared_group)))
          expect(flash[:alert]).to eq('Please select a group.')
        end
      end

      context 'when link is not persisted in the database' do
        before do
          allow(::Groups::GroupLinks::CreateService).to(
            receive_message_chain(:new, :execute)
              .and_return({ status: :error,
                            http_status: 409,
                            message: 'error' }))
        end

        it 'redirects to group links page' do
          subject

          expect(response).to(redirect_to(group_group_members_path(shared_group)))
          expect(flash[:alert]).to eq('error')
        end
      end
    end

    context 'when user does not have access to the group' do
      before do
        shared_group.add_owner(user)
      end

      it 'renders 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user does not have admin access to the shared group' do
      before do
        shared_with_group.add_developer(user)
        shared_group.add_developer(user)
      end

      it 'renders 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    include_examples 'placeholder is passed as `id` parameter', :create
  end

  describe '#update' do
    let!(:link) do
      create(:group_group_link, { shared_group: shared_group,
                                  shared_with_group: shared_with_group })
    end

    let(:expiry_date) { 1.month.from_now.to_date }

    subject do
      post(
        :update,
        params: {
          group_id: shared_group,
          id: link.id,
          group_link: { group_access: Gitlab::Access::GUEST, expires_at: expiry_date }
        },
        format: :json
      )
    end

    context 'when user has admin access to the shared group' do
      before do
        shared_group.add_owner(user)
        shared_with_group.refresh_members_authorized_projects
      end

      it 'updates existing link' do
        expect(link.group_access).to eq(Gitlab::Access::DEVELOPER)
        expect(link.expires_at).to be_nil

        subject

        link.reload

        expect(link.group_access).to eq(Gitlab::Access::GUEST)
        expect(link.expires_at).to eq(expiry_date)
      end

      context 'when `expires_at` is set' do
        it 'returns correct json response' do
          travel_to Time.now.utc.beginning_of_day

          subject

          expect(json_response).to eq({ "expires_in" => "about 1 month", "expires_soon" => false })
        end
      end

      context 'when `expires_at` is not set' do
        let(:expiry_date) { nil }

        it 'returns empty json response' do
          subject

          expect(json_response).to be_empty
        end
      end

      it 'updates project permissions', :sidekiq_inline do
        expect { subject }.to change { group_member.can?(:create_release, project) }.from(true).to(false)
      end
    end

    context 'when user does not have admin access to the shared group' do
      it 'renders 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    include_examples 'placeholder is passed as `id` parameter', :update
  end

  describe '#destroy' do
    let!(:link) do
      create(:group_group_link, { shared_group: shared_group,
                                  shared_with_group: shared_with_group })
    end

    subject do
      post(:destroy, params: { group_id: shared_group,
                               id: link.id })
    end

    context 'when user has admin access to the shared group' do
      before do
        shared_group.add_owner(user)
        shared_with_group.refresh_members_authorized_projects
      end

      it 'deletes existing link' do
        expect { subject }.to change(GroupGroupLink, :count).by(-1)
      end

      it 'updates project permissions', :sidekiq_inline do
        expect { subject }.to change { group_member.can?(:create_release, project) }.from(true).to(false)
      end
    end

    context 'when user does not have admin access to the shared group' do
      it 'renders 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    include_examples 'placeholder is passed as `id` parameter', :destroy
  end
end
