require 'spec_helper'

describe MembersFinder, '#execute' do
  let(:group)        { create(:group) }
  let(:nested_group) { create(:group, :access_requestable, parent: group) }
  let(:project)      { create(:project, namespace: nested_group) }
  let(:user1)        { create(:user) }
  let(:user2)        { create(:user) }
  let(:user3)        { create(:user) }
  let(:user4)        { create(:user) }

  it 'returns members for project and parent groups', :nested_groups do
    nested_group.request_access(user1)
    member1 = group.add_maintainer(user2)
    member2 = nested_group.add_maintainer(user3)
    member3 = project.add_maintainer(user4)

    result = described_class.new(project, user2).execute

    expect(result.to_a).to match_array([member1, member2, member3])
  end

  it 'includes nested group members if asked', :nested_groups do
    project = create(:project, namespace: group)
    nested_group.request_access(user1)
    member1 = group.add_maintainer(user2)
    member2 = nested_group.add_maintainer(user3)
    member3 = project.add_maintainer(user4)

    result = described_class.new(project, user2).execute(include_descendants: true)

    expect(result.to_a).to match_array([member1, member2, member3])
  end
end
