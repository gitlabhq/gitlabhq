# frozen_string_literal: true

require "spec_helper"

RSpec.describe Groups::GroupMembersHelper do
  include MembersPresentation

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    allow(helper).to receive(:can?).with(current_user, :owner_access, group).and_return(true)
    allow(helper).to receive(:current_user).and_return(current_user)
  end

  describe '.group_member_select_options' do
    before do
      helper.instance_variable_set(:@group, group)
    end

    it 'returns an options hash' do
      expect(helper.group_member_select_options).to include(multiple: true, scope: :all, email_user: true)
    end
  end

  describe '#group_members_app_data_json' do
    include_context 'group_group_link'

    let(:members) { create_list(:group_member, 2, group: shared_group, created_by: current_user) }
    let(:invited) { create_list(:group_member, 2, :invited, group: shared_group, created_by: current_user) }
    let!(:access_requests) { create_list(:group_member, 2, :access_request, group: shared_group, created_by: current_user) }

    let(:members_collection) { members }

    subject do
      Gitlab::Json.parse(
        helper.group_members_app_data_json(
          shared_group,
          members: present_members(members_collection),
          invited: present_members(invited),
          access_requests: present_members(access_requests)
        )
      )
    end

    shared_examples 'members.json' do |member_type|
      it 'returns `members` property that matches json schema' do
        expect(subject[member_type]['members'].to_json).to match_schema('members')
      end

      it 'sets `member_path` property' do
        expect(subject[member_type]['member_path']).to eq('/groups/foo-bar/-/group_members/:id')
      end
    end

    before do
      allow(helper).to receive(:group_group_member_path).with(shared_group, ':id').and_return('/groups/foo-bar/-/group_members/:id')
      allow(helper).to receive(:group_group_link_path).with(shared_group, ':id').and_return('/groups/foo-bar/-/group_links/:id')
      allow(helper).to receive(:can?).with(current_user, :admin_group_member, shared_group).and_return(true)
    end

    it 'returns expected json' do
      expected = {
        source_id: shared_group.id,
        can_manage_members: true
      }.as_json

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
        expect(subject['group']['members'].to_json).to match_schema('group_link/group_group_links')
      end

      it 'sets `member_path` property' do
        expect(subject['group']['member_path']).to eq('/groups/foo-bar/-/group_links/:id')
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

        expect(subject['access_request']['pagination']).to include(expected)
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

        expect(subject['user']['pagination']).to include(expected)
      end
    end
  end
end
