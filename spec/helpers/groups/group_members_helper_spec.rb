# frozen_string_literal: true

require "spec_helper"

RSpec.describe Groups::GroupMembersHelper, feature_category: :groups_and_projects do
  include MembersPresentation

  let_it_be(:group) { create(:group) }

  describe '#group_members_app_data' do
    include_context 'group_group_link'

    let_it_be(:current_user) { create(:user) }

    let(:members) { create_list(:group_member, 2, group: shared_group, created_by: current_user) }
    let(:invited) { create_list(:group_member, 2, :invited, group: shared_group, created_by: current_user) }
    let!(:access_requests) { create_list(:group_member, 2, :access_request, group: shared_group, created_by: current_user) }
    let(:available_roles) do
      Gitlab::Access.options_with_owner.map { |name, access_level| { title: name, value: "static-#{access_level}" } }
    end

    let(:members_collection) { members }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
      allow(helper).to receive(:group_group_member_path).with(shared_group, ':id').and_return('/groups/foo-bar/-/group_members/:id')
      allow(helper).to receive(:group_group_link_path).with(shared_group, ':id').and_return('/groups/foo-bar/-/group_links/:id')
    end

    subject do
      helper.group_members_app_data(
        shared_group,
        members: present_members(members_collection),
        invited: present_members(invited),
        access_requests: present_members(access_requests),
        banned: [],
        include_relations: [:inherited, :direct],
        search: nil,
        pending_members_count: nil,
        placeholder_users: {
          pagination: {
            total_items: 3,
            awaiting_reassignment_items: 2,
            reassigned_items: 1
          }
        }
      )
    end

    shared_examples 'members.json' do |member_type|
      it 'returns `members` property that matches json schema' do
        expect(subject[member_type.to_sym][:members].to_json).to match_schema('members')
      end

      it 'sets `member_path` property' do
        expect(subject[member_type.to_sym][:member_path]).to eq('/groups/foo-bar/-/group_members/:id')
      end
    end

    it 'returns expected json' do
      expected = {
        source_id: shared_group.id,
        can_manage_members: be_in([true, false]),
        can_manage_access_requests: be_in([true, false]),
        group_name: shared_group.name,
        group_path: shared_group.full_path,
        can_approve_access_requests: true,
        available_roles: available_roles
      }

      expect(subject).to include(expected)
    end

    context 'group members' do
      it_behaves_like 'members.json', 'user'

      context 'with user status set' do
        let(:user) { create(:user) }
        let!(:status) { create(:user_status, user: user) }
        let(:members) { [create(:group_member, group: shared_group, user: user, created_by: current_user)] }

        it_behaves_like 'members.json', 'user'
      end
    end

    context 'invited group members' do
      it_behaves_like 'members.json', 'invite'
    end

    context 'access requests' do
      it_behaves_like 'members.json', 'access_request'
    end

    context 'group links' do
      it 'sets `group.members` property that matches json schema' do
        expect(subject[:group][:members].to_json).to match_schema('group_link/group_group_links')
      end

      it 'sets `member_path` property' do
        expect(subject[:group][:member_path]).to eq('/groups/foo-bar/-/group_links/:id')
      end

      context 'inherited' do
        let_it_be(:sub_shared_group) { create(:group, parent: shared_group) }
        let_it_be(:sub_shared_with_group) { create(:group) }
        let_it_be(:sub_group_group_link) { create(:group_group_link, shared_group: sub_shared_group, shared_with_group: sub_shared_with_group) }

        let_it_be(:subject_group) { sub_shared_group }

        before do
          allow(helper).to receive(:group_group_member_path).with(sub_shared_group, ':id').and_return('/groups/foo-bar/-/group_members/:id')
          allow(helper).to receive(:group_group_link_path).with(sub_shared_group, ':id').and_return('/groups/foo-bar/-/group_links/:id')
        end

        subject do
          helper.group_members_app_data(
            sub_shared_group,
            members: present_members(members_collection),
            invited: present_members(invited),
            access_requests: present_members(access_requests),
            banned: [],
            include_relations: include_relations,
            search: nil,
            pending_members_count: nil,
            placeholder_users: {}
          )
        end

        using RSpec::Parameterized::TableSyntax

        where(:include_relations, :result) do
          [:inherited, :direct] | lazy { [group_group_link, sub_group_group_link].map(&:id) }
          [:inherited]          | lazy { [group_group_link].map(&:id) }
          [:direct]             | lazy { [sub_group_group_link].map(&:id) }
        end

        with_them do
          it 'returns correct group links' do
            expect(subject[:group][:members].map { |link| link[:id] }).to match_array(result)
          end
        end
      end
    end

    context 'when pagination is not available' do
      it 'sets `pagination` attribute to expected json' do
        expected = {
          current_page: nil,
          per_page: nil,
          total_items: 2,
          param_name: nil,
          params: {}
        }.as_json

        expect(subject[:access_request][:pagination].as_json).to include(expected)
      end
    end

    context 'when pagination is available' do
      let(:members_collection) { Kaminari.paginate_array(members).page(1).per(1) }

      it 'sets `pagination` attribute to expected json' do
        expected = {
          current_page: 1,
          per_page: 1,
          total_items: 2,
          param_name: :page,
          params: { invited_members_page: nil, search_invited: nil }
        }.as_json

        expect(subject[:user][:pagination].as_json).to include(expected)
      end
    end

    context 'when placeholder users data is available' do
      it 'returns placeholder information' do
        expect(subject[:placeholder]).to eq(
          pagination: {
            total_items: 3,
            awaiting_reassignment_items: 2,
            reassigned_items: 1
          }
        )
      end
    end
  end

  describe '#group_member_header_subtext' do
    it 'contains expected text with group name' do
      expect(helper.group_member_header_subtext(group)).to match("You're viewing members of .*#{group.name}")
    end
  end
end
