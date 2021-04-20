# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupMembersFinder, '#execute' do
  let(:group)         { create(:group) }
  let(:sub_group)     { create(:group, parent: group) }
  let(:sub_sub_group) { create(:group, parent: sub_group) }
  let(:user1)         { create(:user) }
  let(:user2)         { create(:user) }
  let(:user3)         { create(:user) }
  let(:user4)         { create(:user) }
  let(:user5)         { create(:user, :two_factor_via_otp) }

  let(:groups) do
    {
      group:         group,
      sub_group:     sub_group,
      sub_sub_group: sub_sub_group
    }
  end

  context 'relations' do
    let!(:members) do
      {
        user1_sub_sub_group: create(:group_member, :maintainer, group: sub_sub_group, user: user1),
        user1_sub_group:     create(:group_member, :developer,  group: sub_group,     user: user1),
        user1_group:         create(:group_member, :reporter,   group: group,         user: user1),
        user2_sub_sub_group: create(:group_member, :reporter,   group: sub_sub_group, user: user2),
        user2_sub_group:     create(:group_member, :developer,  group: sub_group,     user: user2),
        user2_group:         create(:group_member, :maintainer, group: group,         user: user2),
        user3_sub_sub_group: create(:group_member, :developer,  group: sub_sub_group, user: user3, expires_at: 1.day.from_now),
        user3_sub_group:     create(:group_member, :developer,  group: sub_group,     user: user3, expires_at: 2.days.from_now),
        user3_group:         create(:group_member, :reporter,   group: group,         user: user3),
        user4_sub_sub_group: create(:group_member, :reporter,   group: sub_sub_group, user: user4),
        user4_sub_group:     create(:group_member, :developer,  group: sub_group,     user: user4, expires_at: 1.day.from_now),
        user4_group:         create(:group_member, :developer,  group: group,         user: user4, expires_at: 2.days.from_now)
      }
    end

    using RSpec::Parameterized::TableSyntax

    where(:subject_relations, :subject_group, :expected_members) do
      nil                                 | :group         | [:user1_group,         :user2_group,         :user3_group,         :user4_group]
      [:direct]                           | :group         | [:user1_group,         :user2_group,         :user3_group,         :user4_group]
      [:inherited]                        | :group         | []
      [:descendants]                      | :group         | [:user1_sub_sub_group, :user2_sub_group,     :user3_sub_group,     :user4_sub_group]
      [:direct, :inherited]               | :group         | [:user1_group,         :user2_group,         :user3_group,         :user4_group]
      [:direct, :descendants]             | :group         | [:user1_sub_sub_group, :user2_group,         :user3_sub_group,     :user4_group]
      [:descendants, :inherited]          | :group         | [:user1_sub_sub_group, :user2_sub_group,     :user3_sub_group,     :user4_sub_group]
      [:direct, :descendants, :inherited] | :group         | [:user1_sub_sub_group, :user2_group,         :user3_sub_group,     :user4_group]
      nil                                 | :sub_group     | [:user1_sub_group,     :user2_group,         :user3_sub_group,     :user4_group]
      [:direct]                           | :sub_group     | [:user1_sub_group,     :user2_sub_group,     :user3_sub_group,     :user4_sub_group]
      [:inherited]                        | :sub_group     | [:user1_group,         :user2_group,         :user3_group,         :user4_group]
      [:descendants]                      | :sub_group     | [:user1_sub_sub_group, :user2_sub_sub_group, :user3_sub_sub_group, :user4_sub_sub_group]
      [:direct, :inherited]               | :sub_group     | [:user1_sub_group,     :user2_group,         :user3_sub_group,     :user4_group]
      [:direct, :descendants]             | :sub_group     | [:user1_sub_sub_group, :user2_sub_group,     :user3_sub_group,     :user4_sub_group]
      [:descendants, :inherited]          | :sub_group     | [:user1_sub_sub_group, :user2_group,         :user3_sub_sub_group, :user4_group]
      [:direct, :descendants, :inherited] | :sub_group     | [:user1_sub_sub_group, :user2_group,         :user3_sub_group,     :user4_group]
      nil                                 | :sub_sub_group | [:user1_sub_sub_group, :user2_group,         :user3_sub_group,     :user4_group]
      [:direct]                           | :sub_sub_group | [:user1_sub_sub_group, :user2_sub_sub_group, :user3_sub_sub_group, :user4_sub_sub_group]
      [:inherited]                        | :sub_sub_group | [:user1_sub_group,     :user2_group,         :user3_sub_group,     :user4_group]
      [:descendants]                      | :sub_sub_group | []
      [:direct, :inherited]               | :sub_sub_group | [:user1_sub_sub_group, :user2_group,         :user3_sub_group,     :user4_group]
      [:direct, :descendants]             | :sub_sub_group | [:user1_sub_sub_group, :user2_sub_sub_group, :user3_sub_sub_group, :user4_sub_sub_group]
      [:descendants, :inherited]          | :sub_sub_group | [:user1_sub_group,     :user2_group,         :user3_sub_group,     :user4_group]
      [:direct, :descendants, :inherited] | :sub_sub_group | [:user1_sub_sub_group, :user2_group,         :user3_sub_group,     :user4_group]
    end

    with_them do
      it 'returns correct members' do
        result = if subject_relations
                   described_class.new(groups[subject_group]).execute(include_relations: subject_relations)
                 else
                   described_class.new(groups[subject_group]).execute
                 end

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
end
