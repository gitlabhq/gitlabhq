# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserGroupsCounter do
  subject { described_class.new(user_ids).execute }

  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group1) { create(:group) }
    let_it_be(:group_member1) { create(:group_member, source: group1, user_id: user.id, access_level: Gitlab::Access::OWNER) }
    let_it_be(:user_ids) { [user.id] }

    it 'returns authorized group count for the user' do
      expect(subject[user.id]).to eq(1)
    end

    context 'when request to join group is pending' do
      let_it_be(:pending_group) { create(:group) }
      let_it_be(:pending_group_member) { create(:group_member, requested_at: Time.current.utc, source: pending_group, user_id: user.id) }

      it 'does not include pending group in the count' do
        expect(subject[user.id]).to eq(1)
      end
    end

    context 'when user is part of sub group' do
      let_it_be(:sub_group) { create(:group, parent: create(:group)) }
      let_it_be(:sub_group_member1) { create(:group_member, source: sub_group, user_id: user.id, access_level: Gitlab::Access::DEVELOPER) }

      it 'includes sub group in the count' do
        expect(subject[user.id]).to eq(2)
      end
    end

    context 'when user is part of namespaced project' do
      let_it_be(:project) { create(:project, group: create(:group)) }
      let_it_be(:project_member) { create(:project_member, source: project, user_id: user.id, access_level: Gitlab::Access::REPORTER) }

      it 'includes the project group' do
        expect(subject[user.id]).to eq(2)
      end
    end
  end
end
