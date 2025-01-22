# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupMembersFinder, '#execute', feature_category: :groups_and_projects do
  let_it_be(:group)                { create(:group) }
  let_it_be(:sub_group)            { create(:group, parent: group) }
  let_it_be(:sub_sub_group)        { create(:group, parent: sub_group) }
  let_it_be(:public_invited_group)  { create(:group, :public) }
  let_it_be(:private_invited_group) { create(:group, :private) }
  let_it_be(:user1)                { create(:user) }
  let_it_be(:user2)                { create(:user) }
  let_it_be(:user3)                { create(:user) }
  let_it_be(:user4)                { create(:user) }
  let_it_be(:user5_2fa)            { create(:user, :two_factor_via_otp) }
  let_it_be(:user6)                { create(:user) }
  let_it_be(:user7)                { create(:user) }

  let_it_be(:link) do
    create(:group_group_link, :maintainer, shared_group: group,     shared_with_group: public_invited_group)
    create(:group_group_link, :maintainer, shared_group: sub_group, shared_with_group: private_invited_group)
    create(:group_group_link, :owner, shared_with_group: public_invited_group)
    create(:group_group_link, :owner, shared_with_group: private_invited_group)
    create(:group_group_link, :owner, shared_group: group)
    create(:group_group_link, :owner, shared_group: sub_group)
  end

  let(:groups) do
    {
      group: group,
      sub_group: sub_group,
      sub_sub_group: sub_sub_group,
      public_invited_group: public_invited_group,
      private_invited_group: private_invited_group
    }
  end

  context 'relations' do
    let_it_be(:members) do
      {
        user1_sub_sub_group: create(:group_member, :maintainer, group: sub_sub_group, user: user1),
        user1_sub_group: create(:group_member, :developer, group: sub_group, user: user1),
        user1_group: create(:group_member, :reporter, group: group, user: user1),
        user1_public_shared_group: create(:group_member, :owner, group: public_invited_group, user: user1),
        user1_private_shared_group: create(:group_member, :maintainer, group: private_invited_group, user: user1),
        user2_sub_sub_group: create(:group_member, :reporter, group: sub_sub_group, user: user2),
        user2_sub_group: create(:group_member, :developer, group: sub_group, user: user2),
        user2_group: create(:group_member, :maintainer, group: group, user: user2),
        user2_public_shared_group: create(:group_member, :developer, group: public_invited_group, user: user2),
        user2_private_shared_group: create(:group_member, :developer, group: private_invited_group, user: user2),
        user3_sub_sub_group: create(:group_member, :developer, group: sub_sub_group, user: user3, expires_at: 1.day.from_now),
        user3_sub_group: create(:group_member, :developer, group: sub_group, user: user3, expires_at: 2.days.from_now),
        user3_group: create(:group_member, :reporter, group: group, user: user3),
        user3_public_shared_group: create(:group_member, :reporter, group: public_invited_group, user: user3),
        user3_private_shared_group: create(:group_member, :reporter, group: private_invited_group, user: user3),
        user4_sub_sub_group: create(:group_member, :reporter, group: sub_sub_group, user: user4),
        user4_sub_group: create(:group_member, :developer, group: sub_group, user: user4, expires_at: 1.day.from_now),
        user4_group: create(:group_member, :developer, group: group, user: user4, expires_at: 2.days.from_now),
        user4_public_shared_group: create(:group_member, :maintainer, group: public_invited_group, user: user4),
        user4_private_shared_group: create(:group_member, :maintainer, group: private_invited_group, user: user4),
        user5_private_shared_group: create(:group_member, :maintainer, group: private_invited_group, user: user5_2fa),
        user6_group: create(:group_member, :guest, group: group, user: user6),
        user7_private_invited_group: create(:group_member, :guest, group: private_invited_group, user: user7)
      }
    end

    it 'raises an error if a non-supported relation type is used' do
      expect do
        described_class.new(group).execute(include_relations: [:direct, :invalid_relation_type])
      end.to raise_error(ArgumentError, "invalid_relation_type is not a valid relation type. Valid relation types are direct, inherited, descendants, shared_from_groups.")
    end

    using RSpec::Parameterized::TableSyntax

    where(:subject_relations, :subject_group, :visible_members, :members_visible_only_to_shared_group_members) do
      []                                                       | :group         | []                                                                                                                 | []
      GroupMembersFinder::DEFAULT_RELATIONS                    | :group         | [:user1_group, :user2_group, :user3_group, :user4_group, :user6_group]                                             | []
      [:direct]                                                | :group         | [:user1_group, :user2_group, :user3_group, :user4_group, :user6_group]                                             | []
      [:inherited]                                             | :group         | []                                                                                                                 | []
      [:descendants]                                           | :group         | [:user1_sub_sub_group, :user2_sub_group, :user3_sub_group, :user4_sub_group]                                       | []
      [:shared_from_groups]                                    | :group         | [:user1_public_shared_group, :user2_public_shared_group, :user3_public_shared_group, :user4_public_shared_group]   | []
      [:direct, :inherited, :descendants, :shared_from_groups] | :group         | [:user1_sub_sub_group, :user2_group, :user3_sub_group, :user4_public_shared_group, :user6_group]                   | []
      []                                                       | :sub_group     | []                                                                                                                 | []
      GroupMembersFinder::DEFAULT_RELATIONS                    | :sub_group     | [:user1_sub_group, :user2_group, :user3_sub_group, :user4_sub_group, :user6_group] | []
      [:direct]                                                | :sub_group     | [:user1_sub_group, :user2_sub_group, :user3_sub_group, :user4_sub_group]                                           | []
      [:inherited]                                             | :sub_group     | [:user1_group, :user2_group, :user3_group, :user4_group, :user6_group]                                             | []
      [:descendants]                                           | :sub_group     | [:user1_sub_sub_group, :user2_sub_sub_group, :user3_sub_sub_group, :user4_sub_sub_group]                           | []
      [:shared_from_groups]                                    | :sub_group     | [:user1_public_shared_group, :user2_public_shared_group, :user3_public_shared_group, :user4_public_shared_group]   | [:user5_private_shared_group, :user7_private_invited_group]
      [:direct, :inherited, :descendants, :shared_from_groups] | :sub_group     | [:user1_sub_sub_group, :user2_group, :user3_sub_group, :user4_public_shared_group, :user6_group]                   | [:user5_private_shared_group, :user7_private_invited_group]
      []                                                       | :sub_sub_group | []                                                                                                                 | []
      GroupMembersFinder::DEFAULT_RELATIONS                    | :sub_sub_group | [:user1_sub_sub_group, :user2_group, :user3_sub_sub_group, :user4_group, :user6_group] | []
      [:direct]                                                | :sub_sub_group | [:user1_sub_sub_group, :user2_sub_sub_group, :user3_sub_sub_group, :user4_sub_sub_group]                           | []
      [:inherited]                                             | :sub_sub_group | [:user1_sub_group, :user2_group, :user3_sub_group, :user4_group, :user6_group]                                     | []
      [:descendants]                                           | :sub_sub_group | []                                                                                                                 | []
      [:shared_from_groups]                                    | :sub_sub_group | [:user1_public_shared_group, :user2_public_shared_group, :user3_public_shared_group, :user4_public_shared_group]   | [:user5_private_shared_group, :user7_private_invited_group]
      [:direct, :inherited, :descendants, :shared_from_groups] | :sub_sub_group | [:user1_sub_sub_group, :user2_group, :user3_sub_sub_group, :user4_public_shared_group, :user6_group] | [:user5_private_shared_group, :user7_private_invited_group]
    end

    with_them do
      it 'returns correct members' do
        result = described_class.new(groups[subject_group]).execute(include_relations: subject_relations)

        expect(result.to_a).to match_array(visible_members.map { |name| members[name] })
      end

      context 'when current user is a member of the shared group and not of invited groups' do
        it 'returns private invited group members' do
          result = described_class.new(groups[subject_group], user6).execute(include_relations: subject_relations)

          expected_members = (visible_members + members_visible_only_to_shared_group_members).map { |name| members[name] }
          expect(result.to_a).to match_array(expected_members)
        end
      end
    end

    it 'returns the correct access level of the members shared through group sharing' do
      shared_members_access = described_class
                                .new(groups[:sub_group], user6)
                                .execute(include_relations: [:shared_from_groups])
                                .to_a
                                .map(&:access_level)

      correct_access_levels = ([Gitlab::Access::MAINTAINER] * 3) + [Gitlab::Access::GUEST, Gitlab::Access::REPORTER, Gitlab::Access::DEVELOPER]
      expect(shared_members_access).to match_array(correct_access_levels)
    end
  end

  context 'search' do
    before_all do
      group.add_maintainer(user2)
      group.add_developer(user3)
    end

    let_it_be(:maintainer1) { group.add_maintainer(user1) }

    it 'returns searched members if requested' do
      result = described_class.new(group, params: { search: user1.name }).execute

      expect(result.to_a).to match_array([maintainer1])
    end

    it 'returns nothing if search only in inherited relation' do
      result = described_class.new(group, params: { search: user1.name }).execute(include_relations: [:inherited])

      expect(result.to_a).to be_empty
    end

    it 'returns searched member only from sub_group if search only in inherited relation' do
      sub_group.add_maintainer(create(:user, name: user1.name))

      result = described_class.new(sub_group, params: { search: maintainer1.user.name }).execute(include_relations: [:inherited])

      expect(result.to_a).to contain_exactly(maintainer1)
    end
  end

  context 'filter by two-factor' do
    it 'returns members with two-factor auth if requested by owner' do
      group.add_owner(user2)
      group.add_maintainer(user1)
      member = group.add_maintainer(user5_2fa)

      result = described_class.new(group, user2, params: { two_factor: 'enabled' }).execute

      expect(result.to_a).to contain_exactly(member)
    end

    it 'returns members without two-factor auth if requested by owner' do
      member1 = group.add_owner(user2)
      member2 = group.add_maintainer(user1)
      member_with_2fa = group.add_maintainer(user5_2fa)

      result = described_class.new(group, user2, params: { two_factor: 'disabled' }).execute

      expect(result.to_a).not_to include(member_with_2fa)
      expect(result.to_a).to match_array([member1, member2])
    end

    it 'returns direct members with two-factor auth if requested by owner' do
      group.add_owner(user1)
      group.add_maintainer(user2)
      sub_group.add_maintainer(user3)
      member_with_2fa = sub_group.add_maintainer(user5_2fa)

      result = described_class.new(sub_group, user1, params: { two_factor: 'enabled' }).execute(include_relations: [:direct])

      expect(result.to_a).to match_array([member_with_2fa])
    end

    it 'returns inherited members with two-factor auth if requested by owner' do
      group.add_owner(user1)
      member_with_2fa = group.add_maintainer(user5_2fa)
      sub_group.add_maintainer(user2)
      sub_group.add_maintainer(user3)

      result = described_class.new(sub_group, user1, params: { two_factor: 'enabled' }).execute(include_relations: [:inherited])

      expect(result.to_a).to match_array([member_with_2fa])
    end

    it 'returns direct members without two-factor auth if requested by owner' do
      group.add_owner(user1)
      group.add_maintainer(user2)
      member3 = sub_group.add_maintainer(user3)
      sub_group.add_maintainer(user5_2fa)

      result = described_class.new(sub_group, user1, params: { two_factor: 'disabled' }).execute(include_relations: [:direct])

      expect(result.to_a).to match_array([member3])
    end

    it 'returns inherited members without two-factor auth if requested by owner' do
      member1 = group.add_owner(user1)
      group.add_maintainer(user5_2fa)
      sub_group.add_maintainer(user2)
      sub_group.add_maintainer(user3)

      result = described_class.new(sub_group, user1, params: { two_factor: 'disabled' }).execute(include_relations: [:inherited])

      expect(result.to_a).to match_array([member1])
    end
  end

  context 'filter by access levels' do
    let_it_be(:owner1) { group.add_owner(user2) }
    let_it_be(:owner2) { group.add_owner(user3) }
    let_it_be(:maintainer1) { group.add_maintainer(user4) }
    let_it_be(:maintainer2) { group.add_maintainer(user5_2fa) }

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

  context 'filter by user type' do
    subject(:by_user_type) { described_class.new(group, user1, params: { user_type: user_type }).execute }

    let_it_be(:service_account) { create(:user, :service_account) }
    let_it_be(:project_bot) { create(:user, :project_bot) }

    let_it_be(:service_account_member) { group.add_developer(service_account) }
    let_it_be(:project_bot_member) { group.add_developer(project_bot) }

    context 'when the user is an owner' do
      before do
        group.add_owner(user1)
      end

      context 'when filtering by project bots' do
        let(:user_type) { 'project_bot' }

        it 'returns filtered members' do
          expect(by_user_type).to match_array([project_bot_member])
        end
      end

      context 'when filtering by service accounts' do
        let(:user_type) { 'service_account' }

        it 'returns filtered members' do
          expect(by_user_type).to match_array([service_account_member])
        end
      end
    end

    context 'when the user is a maintainer' do
      let(:user_type) { 'service_account' }

      let_it_be(:user1_member) { group.add_maintainer(user1) }

      it 'returns unfiltered members' do
        expect(by_user_type).to match_array([user1_member, service_account_member, project_bot_member])
      end
    end

    context 'when the user is a developer' do
      let(:user_type) { 'service_account' }

      let_it_be(:user1_member) { group.add_developer(user1) }

      it 'returns unfiltered members' do
        expect(by_user_type).to match_array([user1_member, service_account_member, project_bot_member])
      end
    end
  end

  context 'filter by max role' do
    subject(:by_max_role) { described_class.new(group, user1, params: { max_role: max_role }).execute }

    let_it_be(:guest_member) { create(:group_member, :guest, group: group, user: user2) }
    let_it_be(:owner_member) { create(:group_member, :owner, group: group, user: user3) }

    describe 'provided access level is incorrect' do
      where(:max_role) { [nil, '', 'static', 'xstatic-50', 'static-50x', 'static-99'] }

      with_them do
        it { is_expected.to match_array(group.members) }
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

  context 'filter by non-invite' do
    let_it_be(:member) { group.add_maintainer(user1) }
    let_it_be(:invited_member) do
      create(:group_member, :invited, { user: user2, group: group })
    end

    context 'params is not passed in' do
      subject { described_class.new(group, user1).execute }

      it 'does not filter members by invite' do
        expect(subject).to match_array([member, invited_member])
      end
    end

    context 'params is passed in' do
      subject { described_class.new(group, user1, params: { non_invite: non_invite_param }).execute }

      context 'filtering is set to false' do
        let(:non_invite_param) { false }

        it 'does not filter members by invite' do
          expect(subject).to match_array([member, invited_member])
        end
      end

      context 'filtering is set to true' do
        let(:non_invite_param) { true }

        it 'filters members by invite' do
          expect(subject).to match_array([member])
        end
      end
    end
  end
end
