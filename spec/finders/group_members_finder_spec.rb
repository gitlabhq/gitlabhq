require 'spec_helper'

describe GroupMembersFinder, '#execute' do
  let(:group)        { create(:group) }
  let(:nested_group) { create(:group, :access_requestable, parent: group) }
  let(:user1)        { create(:user) }
  let(:user2)        { create(:user) }
  let(:user3)        { create(:user) }
  let(:user4)        { create(:user) }

  it 'returns members for top-level group' do
    member1 = group.add_master(user1)
    member2 = group.add_master(user2)
    member3 = group.add_master(user3)

    result = described_class.new(group).execute

    expect(result.to_a).to match_array([member3, member2, member1])
  end

  it 'returns members for nested group', :nested_groups do
    group.add_master(user2)
    nested_group.request_access(user4)
    member1 = group.add_master(user1)
    member3 = nested_group.add_master(user2)
    member4 = nested_group.add_master(user3)

    result = described_class.new(nested_group).execute

    expect(result.to_a).to match_array([member1, member3, member4])
  end
end
