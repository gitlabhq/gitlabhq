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

  describe '#group_members_list_data_json' do
    let(:group_members) { create_list(:group_member, 2, group: group, created_by: current_user) }

    let(:pagination) { {} }
    let(:collection) { group_members }
    let(:presented_members) { present_members(collection) }

    subject { Gitlab::Json.parse(helper.group_members_list_data_json(group, presented_members, pagination)) }

    shared_examples 'members.json' do
      it 'returns `members` property that matches json schema' do
        expect(subject['members'].to_json).to match_schema('members')
      end
    end

    before do
      allow(helper).to receive(:group_group_member_path).with(group, ':id').and_return('/groups/foo-bar/-/group_members/:id')
      allow(helper).to receive(:can?).with(current_user, :admin_group_member, group).and_return(true)
    end

    it 'returns expected json' do
      expected = {
        member_path: '/groups/foo-bar/-/group_members/:id',
        source_id: group.id,
        can_manage_members: true
      }.as_json

      expect(subject).to include(expected)
    end

    context 'for a group member' do
      it_behaves_like 'members.json'

      context 'with user status set' do
        let(:user) { create(:user) }
        let!(:status) { create(:user_status, user: user) }
        let(:group_members) { [create(:group_member, group: group, user: user, created_by: current_user)] }

        it_behaves_like 'members.json'
      end
    end

    context 'for an invited group member' do
      let(:group_members) { create_list(:group_member, 2, :invited, group: group, created_by: current_user) }

      it_behaves_like 'members.json'
    end

    context 'for an access request' do
      let(:group_members) { create_list(:group_member, 2, :access_request, group: group, created_by: current_user) }

      it_behaves_like 'members.json'
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

        expect(subject['pagination']).to include(expected)
      end
    end

    context 'when pagination is available' do
      let(:collection) { Kaminari.paginate_array(group_members).page(1).per(1) }
      let(:pagination) { { param_name: :page, params: { search_groups: nil } } }

      it 'sets `pagination` attribute to expected json' do
        expected = {
          current_page: 1,
          per_page: 1,
          total_items: 2,
          param_name: :page,
          params: { search_groups: nil }
        }.as_json

        expect(subject['pagination']).to include(expected)
      end
    end
  end

  describe '#group_group_links_list_data_json' do
    include_context 'group_group_link'

    subject { Gitlab::Json.parse(helper.group_group_links_list_data_json(shared_group)) }

    before do
      allow(helper).to receive(:group_group_link_path).with(shared_group, ':id').and_return('/groups/foo-bar/-/group_links/:id')
    end

    it 'returns expected json' do
      expected = {
        pagination: {
          current_page: nil,
          per_page: nil,
          total_items: 1,
          param_name: nil,
          params: {}
        },
        member_path: '/groups/foo-bar/-/group_links/:id',
        source_id: shared_group.id
      }.as_json

      expect(subject).to include(expected)
    end

    it 'returns `members` property that matches json schema' do
      expect(subject['members'].to_json).to match_schema('group_link/group_group_links')
    end
  end
end
