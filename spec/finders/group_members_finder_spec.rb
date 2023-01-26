# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupMembersFinder, '#execute', feature_category: :subgroups do
  let_it_be(:group)                { create(:group) }
  let_it_be(:sub_group)            { create(:group, parent: group) }
  let_it_be(:sub_sub_group)        { create(:group, parent: sub_group) }
  let_it_be(:public_shared_group)  { create(:group, :public) }
  let_it_be(:private_shared_group) { create(:group, :private) }
  let_it_be(:user1)                { create(:user) }
  let_it_be(:user2)                { create(:user) }
  let_it_be(:user3)                { create(:user) }
  let_it_be(:user4)                { create(:user) }
  let_it_be(:user5)                { create(:user, :two_factor_via_otp) }

  let!(:link) do
    create(:group_group_link, shared_group: group,     shared_with_group: public_shared_group)
    create(:group_group_link, shared_group: sub_group, shared_with_group: private_shared_group)
  end

  let(:groups) do
    {
      group: group,
      sub_group: sub_group,
      sub_sub_group: sub_sub_group,
      public_shared_group: public_shared_group,
      private_shared_group: private_shared_group
    }
  end

  context 'relations' do
    let!(:members) do
      {
        user1_sub_sub_group: create(:group_member, :maintainer, group: sub_sub_group, user: user1),
        user1_sub_group: create(:group_member, :developer, group: sub_group, user: user1),
        user1_group: create(:group_member, :reporter, group: group, user: user1),
        user1_public_shared_group: create(:group_member, :maintainer, group: public_shared_group, user: user1),
        user1_private_shared_group: create(:group_member, :maintainer, group: private_shared_group, user: user1),
        user2_sub_sub_group: create(:group_member, :reporter, group: sub_sub_group, user: user2),
        user2_sub_group: create(:group_member, :developer, group: sub_group, user: user2),
        user2_group: create(:group_member, :maintainer, group: group, user: user2),
        user2_public_shared_group: create(:group_member, :developer, group: public_shared_group, user: user2),
        user2_private_shared_group: create(:group_member, :developer, group: private_shared_group, user: user2),
        user3_sub_sub_group: create(:group_member, :developer, group: sub_sub_group, user: user3, expires_at: 1.day.from_now),
        user3_sub_group: create(:group_member, :developer, group: sub_group, user: user3, expires_at: 2.days.from_now),
        user3_group: create(:group_member, :reporter, group: group, user: user3),
        user3_public_shared_group: create(:group_member, :reporter, group: public_shared_group, user: user3),
        user3_private_shared_group: create(:group_member, :reporter, group: private_shared_group, user: user3),
        user4_sub_sub_group: create(:group_member, :reporter, group: sub_sub_group, user: user4),
        user4_sub_group: create(:group_member, :developer, group: sub_group, user: user4, expires_at: 1.day.from_now),
        user4_group: create(:group_member, :developer, group: group, user: user4, expires_at: 2.days.from_now),
        user4_public_shared_group: create(:group_member, :developer, group: public_shared_group, user: user4),
        user4_private_shared_group: create(:group_member, :developer,  group: private_shared_group, user: user4),
        user5_private_shared_group: create(:group_member, :developer,  group: private_shared_group, user: user5)
      }
    end

    it 'raises an error if a non-supported relation type is used' do
      expect do
        described_class.new(group).execute(include_relations: [:direct, :invalid_relation_type])
      end.to raise_error(ArgumentError, "invalid_relation_type is not a valid relation type. Valid relation types are direct, inherited, descendants, shared_from_groups.")
    end

    using RSpec::Parameterized::TableSyntax

    where(:subject_relations, :subject_group, :expected_members) do
      []                                                       | :group         | []
      GroupMembersFinder::DEFAULT_RELATIONS                    | :group         | [:user1_group, :user2_group, :user3_group, :user4_group]
      [:direct]                                                | :group         | [:user1_group, :user2_group, :user3_group, :user4_group]
      [:inherited]                                             | :group         | []
      [:descendants]                                           | :group         | [:user1_sub_sub_group, :user2_sub_group, :user3_sub_group, :user4_sub_group]
      [:shared_from_groups]                                    | :group         | [:user1_public_shared_group, :user2_public_shared_group, :user3_public_shared_group, :user4_public_shared_group]
      [:direct, :inherited, :descendants, :shared_from_groups] | :group         | [:user1_sub_sub_group, :user2_group, :user3_sub_group, :user4_public_shared_group]
      []                                                       | :sub_group     | []
      GroupMembersFinder::DEFAULT_RELATIONS                    | :sub_group     | [:user1_sub_group, :user2_group, :user3_sub_group, :user4_group]
      [:direct]                                                | :sub_group     | [:user1_sub_group, :user2_sub_group, :user3_sub_group, :user4_sub_group]
      [:inherited]                                             | :sub_group     | [:user1_group, :user2_group, :user3_group, :user4_group]
      [:descendants]                                           | :sub_group     | [:user1_sub_sub_group, :user2_sub_sub_group, :user3_sub_sub_group, :user4_sub_sub_group]
      [:shared_from_groups]                                    | :sub_group     | [:user1_public_shared_group, :user2_public_shared_group, :user3_public_shared_group, :user4_public_shared_group]
      [:direct, :inherited, :descendants, :shared_from_groups] | :sub_group     | [:user1_sub_sub_group, :user2_group, :user3_sub_group, :user4_public_shared_group]
      []                                                       | :sub_sub_group | []
      GroupMembersFinder::DEFAULT_RELATIONS                    | :sub_sub_group | [:user1_sub_sub_group, :user2_group, :user3_sub_group, :user4_group]
      [:direct]                                                | :sub_sub_group | [:user1_sub_sub_group, :user2_sub_sub_group, :user3_sub_sub_group, :user4_sub_sub_group]
      [:inherited]                                             | :sub_sub_group | [:user1_sub_group, :user2_group, :user3_sub_group, :user4_group]
      [:descendants]                                           | :sub_sub_group | []
      [:shared_from_groups]                                    | :sub_sub_group | [:user1_public_shared_group, :user2_public_shared_group, :user3_public_shared_group, :user4_public_shared_group]
      [:direct, :inherited, :descendants, :shared_from_groups] | :sub_sub_group | [:user1_sub_sub_group, :user2_group, :user3_sub_group, :user4_public_shared_group]
    end

    with_them do
      it 'returns correct members' do
        result = described_class.new(groups[subject_group]).execute(include_relations: subject_relations)

        expect(result.to_a).to match_array(expected_members.map { |name| members[name] })
      end
    end
  end

  context 'search' do
    it 'returns searched members if requested' do
      group.add_maintainer(user2)
      group.add_developer(user3)
      member = group.add_maintainer(user1)

      result = described_class.new(group, params: { search: user1.name }).execute

      expect(result.to_a).to match_array([member])
    end

    it 'returns nothing if search only in inherited relation' do
      group.add_maintainer(user2)
      group.add_developer(user3)
      group.add_maintainer(user1)

      result = described_class.new(group, params: { search: user1.name }).execute(include_relations: [:inherited])

      expect(result.to_a).to match_array([])
    end

    it 'returns searched member only from sub_group if search only in inherited relation' do
      group.add_maintainer(user2)
      group.add_developer(user3)
      sub_group.add_maintainer(create(:user, name: user1.name))
      member = group.add_maintainer(user1)

      result = described_class.new(sub_group, params: { search: member.user.name }).execute(include_relations: [:inherited])

      expect(result.to_a).to contain_exactly(member)
    end
  end

  context 'filter by two-factor' do
    it 'returns members with two-factor auth if requested by owner' do
      group.add_owner(user2)
      group.add_maintainer(user1)
      member = group.add_maintainer(user5)

      result = described_class.new(group, user2, params: { two_factor: 'enabled' }).execute

      expect(result.to_a).to contain_exactly(member)
    end

    it 'returns members without two-factor auth if requested by owner' do
      member1 = group.add_owner(user2)
      member2 = group.add_maintainer(user1)
      member_with_2fa = group.add_maintainer(user5)

      result = described_class.new(group, user2, params: { two_factor: 'disabled' }).execute

      expect(result.to_a).not_to include(member_with_2fa)
      expect(result.to_a).to match_array([member1, member2])
    end

    it 'returns direct members with two-factor auth if requested by owner' do
      group.add_owner(user1)
      group.add_maintainer(user2)
      sub_group.add_maintainer(user3)
      member_with_2fa = sub_group.add_maintainer(user5)

      result = described_class.new(sub_group, user1, params: { two_factor: 'enabled' }).execute(include_relations: [:direct])

      expect(result.to_a).to match_array([member_with_2fa])
    end

    it 'returns inherited members with two-factor auth if requested by owner' do
      group.add_owner(user1)
      member_with_2fa = group.add_maintainer(user5)
      sub_group.add_maintainer(user2)
      sub_group.add_maintainer(user3)

      result = described_class.new(sub_group, user1, params: { two_factor: 'enabled' }).execute(include_relations: [:inherited])

      expect(result.to_a).to match_array([member_with_2fa])
    end

    it 'returns direct members without two-factor auth if requested by owner' do
      group.add_owner(user1)
      group.add_maintainer(user2)
      member3 = sub_group.add_maintainer(user3)
      sub_group.add_maintainer(user5)

      result = described_class.new(sub_group, user1, params: { two_factor: 'disabled' }).execute(include_relations: [:direct])

      expect(result.to_a).to match_array([member3])
    end

    it 'returns inherited members without two-factor auth if requested by owner' do
      member1 = group.add_owner(user1)
      group.add_maintainer(user5)
      sub_group.add_maintainer(user2)
      sub_group.add_maintainer(user3)

      result = described_class.new(sub_group, user1, params: { two_factor: 'disabled' }).execute(include_relations: [:inherited])

      expect(result.to_a).to match_array([member1])
    end
  end

  context 'filter by access levels' do
    let!(:owner1) { group.add_owner(user2) }
    let!(:owner2) { group.add_owner(user3) }
    let!(:maintainer1) { group.add_maintainer(user4) }
    let!(:maintainer2) { group.add_maintainer(user5) }

    subject(:by_access_levels) { described_class.new(group, user1, params: { access_levels: access_levels }).execute }

    context 'by owner' do
      let(:access_levels) { ::Gitlab::Access::OWNER }

      it 'returns owners' do
        expect(by_access_levels).to match_array([owner1, owner2])
      end
    end

    context 'by maintainer' do
      let(:access_levels) { ::Gitlab::Access::MAINTAINER }

      it 'returns owners' do
        expect(by_access_levels).to match_array([maintainer1, maintainer2])
      end
    end

    context 'by owner and maintainer' do
      let(:access_levels) { [::Gitlab::Access::OWNER, ::Gitlab::Access::MAINTAINER] }

      it 'returns owners and maintainers' do
        expect(by_access_levels).to match_array([owner1, owner2, maintainer1, maintainer2])
      end
    end
  end
end
