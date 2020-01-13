# frozen_string_literal: true

require 'spec_helper'

describe GroupMembersFinder, '#execute' do
  let(:group) { create(:group) }
  let(:nested_group) { create(:group, parent: group) }
  let(:deeper_nested_group) { create(:group, parent: nested_group) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:user4) { create(:user) }
  let(:user5) { create(:user, :two_factor_via_otp) }

  it 'returns members for top-level group' do
    member1 = group.add_maintainer(user1)
    member2 = group.add_maintainer(user2)
    member3 = group.add_maintainer(user3)

    result = described_class.new(group).execute

    expect(result.to_a).to match_array([member3, member2, member1])
  end

  it 'returns members & inherited members for nested group by default' do
    group.add_developer(user2)
    nested_group.request_access(user4)
    member1 = group.add_maintainer(user1)
    member3 = nested_group.add_maintainer(user2)
    member4 = nested_group.add_maintainer(user3)

    result = described_class.new(nested_group).execute

    expect(result.to_a).to match_array([member1, member3, member4])
  end

  it 'does not return inherited members for nested group if requested' do
    group.add_maintainer(user1)
    group.add_developer(user2)
    member2 = nested_group.add_maintainer(user2)
    member3 = nested_group.add_maintainer(user3)

    result = described_class.new(nested_group).execute(include_relations: [:direct])

    expect(result.to_a).to match_array([member2, member3])
  end

  it 'returns only inherited members for nested group if requested' do
    group.add_developer(user2)
    nested_group.request_access(user4)
    member1 = group.add_maintainer(user1)
    nested_group.add_maintainer(user2)
    nested_group.add_maintainer(user3)

    result = described_class.new(nested_group).execute(include_relations: [:inherited])

    expect(result.to_a).to match_array([member1])
  end

  it 'returns members for descendant groups if requested' do
    member1 = group.add_maintainer(user2)
    member2 = group.add_maintainer(user1)
    nested_group.add_maintainer(user2)
    member3 = nested_group.add_maintainer(user3)
    member4 = nested_group.add_maintainer(user4)

    result = described_class.new(group).execute(include_relations: [:direct, :descendants])

    expect(result.to_a).to match_array([member1, member2, member3, member4])
  end

  it 'returns searched members if requested' do
    group.add_maintainer(user2)
    nested_group.add_maintainer(user2)
    nested_group.add_maintainer(user3)
    nested_group.add_maintainer(user4)
    member = group.add_maintainer(user1)

    result = described_class.new(group).execute(include_relations: [:direct, :descendants], params: { search: user1.name })

    expect(result.to_a).to match_array([member])
  end

  it 'returns members with two-factor auth if requested by owner' do
    group.add_owner(user2)
    group.add_maintainer(user1)
    nested_group.add_maintainer(user2)
    nested_group.add_maintainer(user3)
    nested_group.add_maintainer(user4)
    member = group.add_maintainer(user5)

    result = described_class.new(group, user2).execute(include_relations: [:direct, :descendants], params: { two_factor: 'enabled' })

    expect(result.to_a).to contain_exactly(member)
  end

  it 'returns members without two-factor auth if requested by owner' do
    member1 = group.add_owner(user2)
    member2 = group.add_maintainer(user1)
    nested_group.add_maintainer(user2)
    member3 = nested_group.add_maintainer(user3)
    member4 = nested_group.add_maintainer(user4)
    member_with_2fa = group.add_maintainer(user5)

    result = described_class.new(group, user2).execute(include_relations: [:direct, :descendants], params: { two_factor: 'disabled' })

    expect(result.to_a).not_to include(member_with_2fa)
    expect(result.to_a).to match_array([member1, member2, member3, member4])
  end
end
