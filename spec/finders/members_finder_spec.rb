# frozen_string_literal: true

require 'spec_helper'

describe MembersFinder, '#execute' do
  set(:group)        { create(:group) }
  set(:nested_group) { create(:group, parent: group) }
  set(:project)      { create(:project, namespace: nested_group) }
  set(:user1)        { create(:user) }
  set(:user2)        { create(:user) }
  set(:user3)        { create(:user) }
  set(:user4)        { create(:user) }

  it 'returns members for project and parent groups' do
    nested_group.request_access(user1)
    member1 = group.add_maintainer(user2)
    member2 = nested_group.add_maintainer(user3)
    member3 = project.add_maintainer(user4)

    result = described_class.new(project, user2).execute

    expect(result).to contain_exactly(member1, member2, member3)
  end

  it 'includes only non-invite members if user do not have amdin permissions on project' do
    create(:project_member, :invited, project: project, invite_email: create(:user).email)
    member1 = project.add_maintainer(user1)
    member2 = project.add_developer(user2)

    result = described_class.new(project, user2).execute(include_relations: [:direct])

    expect(result).to contain_exactly(member1, member2)
  end

  it 'includes invited members if user have admin permissions on project' do
    member_invite = create(:project_member, :invited, project: project, invite_email: create(:user).email)
    member1 = project.add_maintainer(user1)
    member2 = project.add_maintainer(user2)

    result = described_class.new(project, user2).execute(include_relations: [:direct])

    expect(result).to contain_exactly(member1, member2, member_invite)
  end

  it 'includes nested group members if asked', :nested_groups do
    nested_group.request_access(user1)
    member1 = group.add_maintainer(user2)
    member2 = nested_group.add_maintainer(user3)
    member3 = project.add_maintainer(user4)

    result = described_class.new(project, user2).execute(include_relations: [:direct, :descendants])

    expect(result).to contain_exactly(member1, member2, member3)
  end

  it 'returns only members of project if asked' do
    nested_group.request_access(user1)
    group.add_maintainer(user2)
    nested_group.add_maintainer(user3)
    member4 = project.add_maintainer(user4)

    result = described_class.new(project, user2).execute(include_relations: [:direct])

    expect(result).to contain_exactly(member4)
  end

  it 'returns only inherited members of project if asked' do
    nested_group.request_access(user1)
    member2 = group.add_maintainer(user2)
    member3 = nested_group.add_maintainer(user3)
    project.add_maintainer(user4)

    result = described_class.new(project, user2).execute(include_relations: [:inherited])

    expect(result).to contain_exactly(member2, member3)
  end

  it 'returns the members.access_level when the user is invited', :nested_groups do
    member_invite = create(:project_member, :invited, project: project, invite_email: create(:user).email)
    member1 = group.add_maintainer(user2)

    result = described_class.new(project, user2).execute(include_relations: [:direct, :descendants])

    expect(result).to contain_exactly(member1, member_invite)
    expect(result.last.access_level).to eq(member_invite.access_level)
  end

  it 'returns the highest access_level for the user', :nested_groups do
    member1 = project.add_guest(user1)
    group.add_developer(user1)
    nested_group.add_reporter(user1)

    result = described_class.new(project, user1).execute(include_relations: [:direct, :descendants])

    expect(result).to contain_exactly(member1)
    expect(result.first.access_level).to eq(Gitlab::Access::DEVELOPER)
  end

  context 'when include_invited_groups_members == true' do
    subject { described_class.new(project, user2).execute(include_relations: [:inherited, :direct, :invited_groups_members]) }

    set(:linked_group) { create(:group, :public) }
    set(:nested_linked_group) { create(:group, parent: linked_group) }
    set(:linked_group_member) { linked_group.add_guest(user1) }
    set(:nested_linked_group_member) { nested_linked_group.add_guest(user2) }

    it 'includes all the invited_groups members including members inherited from ancestor groups' do
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

    context 'when the user is a member of invited group and ancestor groups' do
      it 'returns the highest access_level for the user limited by project_group_link.group_access', :nested_groups do
        create(:project_group_link, project: project, group: nested_linked_group, group_access: Gitlab::Access::REPORTER)
        nested_linked_group.add_developer(user1)

        expect(subject.map(&:user)).to contain_exactly(user1, user2)
        expect(subject.max_by(&:access_level).access_level).to eq(Gitlab::Access::REPORTER)
      end
    end
  end
end
