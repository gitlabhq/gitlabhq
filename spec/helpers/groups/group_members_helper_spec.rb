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

  describe '#linked_groups_data_json' do
    include_context 'group_group_link'

    it 'matches json schema' do
      json = helper.linked_groups_data_json(shared_group.shared_with_group_links)

      expect(json).to match_schema('group_group_links')
    end
  end

  describe '#members_data_json' do
    shared_examples 'group_members.json' do
      it 'matches json schema' do
        json = helper.members_data_json(group, present_members([group_member]))

        expect(json).to match_schema('group_members')
      end
    end

    context 'for a group member' do
      let(:group_member) { create(:group_member, group: group, created_by: current_user) }

      it_behaves_like 'group_members.json'

      context 'with user status set' do
        let(:user) { create(:user) }
        let!(:status) { create(:user_status, user: user) }
        let(:group_member) { create(:group_member, group: group, user: user, created_by: current_user) }

        it_behaves_like 'group_members.json'
      end
    end

    context 'for an invited group member' do
      let(:group_member) { create(:group_member, :invited, group: group, created_by: current_user) }

      it_behaves_like 'group_members.json'
    end

    context 'for an access request' do
      let(:group_member) { create(:group_member, :access_request, group: group, created_by: current_user) }

      it_behaves_like 'group_members.json'
    end
  end

  describe '#group_members_list_data_attributes' do
    let(:group_member) { create(:group_member, group: group, created_by: current_user) }

    before do
      allow(helper).to receive(:group_group_member_path).with(group, ':id').and_return('/groups/foo-bar/-/group_members/:id')
      allow(helper).to receive(:can?).with(current_user, :admin_group_member, group).and_return(true)
    end

    it 'returns expected hash' do
      expect(helper.group_members_list_data_attributes(group, present_members([group_member]))).to include({
        members: helper.members_data_json(group, present_members([group_member])),
        member_path: '/groups/foo-bar/-/group_members/:id',
        group_id: group.id,
        can_manage_members: 'true'
      })
    end
  end

  describe '#linked_groups_list_data_attributes' do
    include_context 'group_group_link'

    before do
      allow(helper).to receive(:group_group_link_path).with(shared_group, ':id').and_return('/groups/foo-bar/-/group_links/:id')
    end

    it 'returns expected hash' do
      expect(helper.linked_groups_list_data_attributes(shared_group)).to include({
        members: helper.linked_groups_data_json(shared_group.shared_with_group_links),
        member_path: '/groups/foo-bar/-/group_links/:id',
        group_id: shared_group.id
      })
    end
  end
end
