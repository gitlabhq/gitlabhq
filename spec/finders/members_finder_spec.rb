require 'spec_helper'

describe MembersFinder, '#execute' do
  set(:group)        { create(:group) }
  set(:nested_group) { create(:group, :access_requestable, parent: group) }
  set(:project)      { create(:project, namespace: nested_group) }
  set(:user1)        { create(:user) }
  set(:user2)        { create(:user) }
  set(:user3)        { create(:user) }
  set(:user4)        { create(:user) }

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

  context 'when include_invited_groups_members == true', :nested_groups do
    subject { described_class.new(project, user2).execute(include_invited_groups_members: true) }

    set(:linked_group) { create(:group, :public, :access_requestable) }
    set(:nested_linked_group) { create(:group, parent: linked_group) }
    set(:linked_group_member) { linked_group.add_developer(user1) }
    set(:nested_linked_group_member) { nested_linked_group.add_developer(user2) }

    it 'includes all the invited_groups members including members inherited from ancestor groups', :nested_groups do
      create(:project_group_link, project: project, group: nested_linked_group)

      expect(subject).to contain_exactly(linked_group_member, nested_linked_group_member)
    end

    it 'includes all the invited_groups members' do
      create(:project_group_link, project: project, group: linked_group)

      expect(subject).to contain_exactly(linked_group_member)
    end

    it 'excludes group_members not visible to the user' do
      create(:project_group_link, project: project, group: linked_group)
      private_linked_group = create(:group, :private)
      private_linked_group.add_developer(user3)
      create(:project_group_link, project: project, group: private_linked_group)

      expect(subject).to contain_exactly(linked_group_member)
    end
  end
end
