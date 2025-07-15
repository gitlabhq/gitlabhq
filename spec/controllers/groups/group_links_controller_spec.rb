# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::GroupLinksController, feature_category: :system_access do
  let_it_be(:shared_with_group) { create(:group, :private) }
  let_it_be(:shared_group) { create(:group, :private) }
  let_it_be(:user) { create(:user) }
  let_it_be(:group_member) { create(:user, developer_of: shared_with_group) }
  let_it_be(:project) { create(:project, group: shared_group) }

  before do
    travel_to DateTime.new(2019, 4, 1)
    sign_in(user)
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

  describe '#update' do
    let_it_be(:link) do
      create(:group_group_link, { shared_group: shared_group, shared_with_group: shared_with_group })
    end

    let(:expiry_date) { 1.month.from_now.to_date }

    subject(:update_group_link) do
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
      before_all do
        shared_group.add_owner(user)
      end

      before do
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

          expect(json_response).to eq({ "expires_in" => controller.helpers.time_ago_with_tooltip(expiry_date),
                                        "expires_soon" => false })
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
    let_it_be_with_reload(:link) do
      create(:group_group_link, { shared_group: shared_group, shared_with_group: shared_with_group })
    end

    subject(:destroy_group_link) do
      post(:destroy, params: { group_id: shared_group, id: link.id })
    end

    context 'when user has admin access to the shared group' do
      before_all do
        shared_group.add_owner(user)
      end

      before do
        shared_with_group.refresh_members_authorized_projects
      end

      it 'deletes existing link' do
        expect { subject }.to change(GroupGroupLink, :count).by(-1)

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(group_group_members_path(shared_group))
        expect(flash[:notice]).to eq(
          'Group invite removed. It might take a few minutes for the changes to user access levels to take effect.'
        )
      end

      context 'with skip_group_share_unlink_auth_refresh feature flag disabled' do
        before do
          stub_feature_flags(skip_group_share_unlink_auth_refresh: false)
        end

        it 'updates project permissions', :sidekiq_inline do
          expect { subject }.to change { group_member.can?(:create_release, project) }.from(true).to(false)
        end
      end

      context 'with skip_group_share_unlink_auth_refresh feature flag enabled' do
        before do
          stub_feature_flags(skip_group_share_unlink_auth_refresh: true)
        end

        it 'maintains project authorization', :sidekiq_inline do
          expect(Ability.allowed?(user, :read_project, project)).to be_truthy
        end
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
