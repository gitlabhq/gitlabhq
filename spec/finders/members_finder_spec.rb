# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MembersFinder, feature_category: :groups_and_projects do
  let_it_be(:group) { create(:group) }
  let_it_be(:nested_group) { create(:group, parent: group) }
  let_it_be(:project, reload: true) { create(:project, namespace: nested_group) }
  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:user3) { create(:user) }
  let_it_be(:user4) { create(:user) }
  let_it_be(:blocked_user) { create(:user, :blocked) }

  it 'returns members for project and parent groups' do
    nested_group.request_access(user1)
    member1 = group.add_maintainer(user2)
    member2 = nested_group.add_maintainer(user3)
    member3 = project.add_maintainer(user4)
    blocked_member = project.add_maintainer(blocked_user)

    result = described_class.new(project, user2).execute

    expect(result).to contain_exactly(member1, member2, member3, blocked_member)
  end

  it 'returns owners and maintainers' do
    member1 = group.add_owner(user1)
    group.add_developer(user2)
    member3 = project.add_maintainer(user3)
    project.add_developer(user4)

    result = described_class.new(project, user2, params: { owners_and_maintainers: true }).execute

    expect(result).to contain_exactly(member1, member3)
  end

  it 'returns active users and excludes invited users' do
    member1 = project.add_maintainer(user2)
    create(:project_member, :invited, project: project, invite_email: create(:user).email)
    project.add_maintainer(blocked_user)

    result = described_class.new(project, user2, params: { active_without_invites_and_requests: true }).execute

    expect(result).to contain_exactly(member1)
  end

  it 'does not return members of parent group with minimal access' do
    nested_group.request_access(user1)
    member1 = group.add_maintainer(user2)
    member2 = nested_group.add_maintainer(user3)
    member3 = project.add_maintainer(user4)
    create(:group_member, :minimal_access, user: create(:user), source: group)

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

  it 'returns only inherited members of a personal project' do
    project = create(:project, namespace: user1.namespace)
    member = project.members.first

    result = described_class.new(project, user1).execute(include_relations: [:inherited])

    expect(result).to contain_exactly(member)
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

  it 'returns searched members if requested' do
    project.add_maintainer(user2)
    project.add_maintainer(user3)
    member3 = project.add_maintainer(user4)

    result = described_class.new(project, user2, params: { search: user4.name }).execute

    expect(result).to contain_exactly(member3)
  end

  it 'returns members sorted by id_desc' do
    member1 = project.add_maintainer(user2)
    member2 = project.add_maintainer(user3)
    member3 = project.add_maintainer(user4)

    result = described_class.new(project, user2, params: { sort: 'id_desc' }).execute

    expect(result).to eq([member3, member2, member1])
  end

  it 'avoids N+1 database queries on accessing user records' do
    project.add_maintainer(user2)

    # warm up
    # We need this warm up because there is 1 query being fired in one of the policies,
    # and policy results are cached. Without a warm up, the control.count will be X queries
    # but the test phase will only fire X-1 queries, due the fact that the
    # result of the policy is already available in the cache.
    described_class.new(project, user2).execute.map(&:user)

    control = ActiveRecord::QueryRecorder.new do
      described_class.new(project, user2).execute.map(&:user)
    end

    create_list(:project_member, 3, project: project)

    expect do
      described_class.new(project, user2).execute.map(&:user)
    end.to issue_same_number_of_queries_as(control)
  end

  context 'with :shared_into_ancestors' do
    let_it_be(:invited_group) do
      create(:group).tap do |invited_group|
        create(:group_group_link, shared_group: nested_group, shared_with_group: invited_group)
      end
    end

    let_it_be(:invited_group_member) { create(:group_member, :developer, group: invited_group, user: user1) }
    let_it_be(:namespace_parent_member) { create(:group_member, :owner, group: group, user: user2) }
    let_it_be(:namespace_member) { create(:group_member, :developer, group: nested_group, user: user3) }
    let_it_be(:project_member) { create(:project_member, :developer, project: project, user: user4) }

    subject(:result) { described_class.new(project, user4).execute(include_relations: include_relations) }

    context 'when :shared_into_ancestors is included in the relations' do
      let(:include_relations) { [:inherited, :direct, :invited_groups, :shared_into_ancestors] }

      it "includes members of groups invited into ancestors of project's group" do
        expect(result).to match_array([namespace_parent_member, namespace_member, invited_group_member, project_member])
      end
    end

    context 'when :shared_into_ancestors is not included in the relations' do
      let(:include_relations) { [:inherited, :direct, :invited_groups] }

      it "does not include members of groups invited into ancestors of project's group" do
        expect(result).to match_array([namespace_parent_member, namespace_member, project_member])
      end
    end
  end

  context 'when :invited_groups is passed' do
    subject(:members) do
      described_class.new(project, user2).execute(include_relations: [:inherited, :direct, :invited_groups])
    end

    let_it_be(:linked_group) { create(:group, parent: group) }
    let_it_be(:nested_linked_group) { create(:group, parent: linked_group) }
    let_it_be(:linked_group_member) { linked_group.add_guest(user1) }
    let_it_be(:nested_linked_group_member) { nested_linked_group.add_guest(user2) }

    it 'includes all the invited_groups members including members inherited from ancestor groups' do
      create(:project_group_link, project: project, group: nested_linked_group)

      expect(members).to contain_exactly(linked_group_member, nested_linked_group_member)
    end

    it 'includes all the invited_groups members' do
      create(:project_group_link, project: project, group: linked_group)

      expect(members).to contain_exactly(linked_group_member)
    end

    it 'excludes group_members not visible to the user' do
      create(:project_group_link, project: project, group: linked_group)
      private_linked_group = create(:group, :private)
      private_linked_group.add_developer(user3)
      create(:project_group_link, project: project, group: private_linked_group)

      expect(members).to contain_exactly(linked_group_member)
    end

    context 'when share with group lock is enabled', :sidekiq_inline do
      let_it_be(:top_group_member) { create(:group_member, :developer, group: group) }
      let_it_be(:double_nested_linked_group) { create(:group, parent: nested_linked_group) }
      let_it_be(:double_nested_linked_group_member) { double_nested_linked_group.add_developer(user3) }

      before_all do
        create(:group_group_link, shared_group: nested_group, shared_with_group: linked_group)
        create(:project_group_link, project: project, group: double_nested_linked_group)
      end

      before do
        project.group.update!(share_with_group_lock: true)
      end

      it 'returns no access for invited group members including members inherited from ancestors of invited groups' do
        expect(member_access_level(nested_linked_group_member)).to eq(Gitlab::Access::NO_ACCESS)
        expect(member_access_level(double_nested_linked_group_member)).to eq(Gitlab::Access::NO_ACCESS)
      end

      it 'returns access of inherited members' do
        expect(member_access_level(top_group_member)).to eq(Gitlab::Access::DEVELOPER)
      end

      it 'returns access of inherited members through group sharing' do
        expect(member_access_level(linked_group_member)).to eq(Gitlab::Access::GUEST)
      end

      def member_access_level(member)
        members.id_in(member).first.access_level
      end
    end

    context 'when current user is a member of the shared project but not of invited group' do
      let_it_be(:project_member) { project.add_maintainer(user2) }
      let_it_be(:private_linked_group) { create(:group, :private) }
      let_it_be(:private_linked_group_member) { private_linked_group.add_developer(user3) }

      before_all do
        create(:project_group_link, project: project, group: private_linked_group)
        create(:project_group_link, project: project, group: linked_group)
      end

      it 'includes members from invited groups not visible to the user' do
        expect(members).to contain_exactly(linked_group_member, private_linked_group_member, project_member)
      end
    end

    context 'when the user is a member of invited group and ancestor groups' do
      it 'returns the highest access_level for the user limited by project_group_link.group_access', :nested_groups do
        create(:project_group_link, project: project, group: nested_linked_group,
          group_access: Gitlab::Access::REPORTER)
        nested_linked_group.add_developer(user1)

        expect(members.map(&:user)).to contain_exactly(user1, user2)
        expect(members.max_by(&:access_level).access_level).to eq(Gitlab::Access::REPORTER)
      end
    end
  end

  context 'when filtering by max role' do
    subject(:by_max_role) { described_class.new(project, user1, params: { max_role: max_role }).execute }

    let_it_be(:guest_member) { create(:project_member, :guest, project: project, user: user2) }
    let_it_be(:owner_member) { create(:project_member, :owner, project: project, user: user3) }

    describe 'provided access level is incorrect' do
      using RSpec::Parameterized::TableSyntax

      where(:max_role) { [nil, '', 'static', 'xstatic-50', 'static-50x', 'static-99'] }

      with_them do
        it { is_expected.to match_array(project.members) }
      end
    end

    describe 'none of the members have the provided access level' do
      let(:max_role) { 'static-20' }

      it { is_expected.to be_empty }
    end

    describe 'one of the members has the provided access level' do
      let(:max_role) { 'static-50' }

      it { is_expected.to contain_exactly(owner_member) }
    end
  end
end
