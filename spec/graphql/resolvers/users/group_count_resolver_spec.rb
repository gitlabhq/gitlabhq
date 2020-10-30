# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Users::GroupCountResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user1) { create(:user) }
    let_it_be(:user2) { create(:user) }
    let_it_be(:group1) { create(:group) }
    let_it_be(:group2) { create(:group) }
    let_it_be(:project) { create(:project, group: create(:group)) }
    let_it_be(:group_member1) { create(:group_member, source: group1, user_id: user1.id, access_level: Gitlab::Access::OWNER) }
    let_it_be(:project_member1) { create(:project_member, source: project, user_id: user1.id, access_level: Gitlab::Access::DEVELOPER) }
    let_it_be(:group_member2) { create(:group_member, source: group2, user_id: user2.id, access_level: Gitlab::Access::DEVELOPER) }

    it 'resolves group count for users' do
      current_user = user1

      result = batch_sync do
        [user1, user2].map { |user| resolve_group_count(user, current_user) }
      end

      expect(result).to eq([2, nil])
    end

    context 'permissions' do
      context 'when current_user is an admin', :enable_admin_mode do
        let_it_be(:admin) { create(:admin) }

        it do
          result = batch_sync do
            [user1, user2].map { |user| resolve_group_count(user, admin) }
          end

          expect(result).to eq([2, 1])
        end
      end

      context 'when current_user does not have access to the requested resource' do
        it do
          result = batch_sync { resolve_group_count(user1, user2) }

          expect(result).to be nil
        end
      end

      context 'when current_user does not exist' do
        it do
          result = batch_sync { resolve_group_count(user1, nil) }

          expect(result).to be nil
        end
      end
    end
  end

  def resolve_group_count(user, current_user)
    resolve(described_class, obj: user, ctx: { current_user: current_user })
  end
end
