# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Projects::Members::EffectiveAccessLevelFinder, '#execute' do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  # The result set is being converted to json just for the ease of testing.
  subject { described_class.new(project).execute.as_json }

  context 'for a personal project' do
    let_it_be(:project) { create(:project) }

    shared_examples_for 'includes access level of the owner of the project as Maintainer' do
      it 'includes access level of the owner of the project as Maintainer' do
        expect(subject).to(
          contain_exactly(
            hash_including(
              'user_id' => project.namespace.owner.id,
              'access_level' => Gitlab::Access::MAINTAINER
            )
          )
        )
      end
    end

    context 'when the project owner is a member of the project' do
      it_behaves_like 'includes access level of the owner of the project as Maintainer'
    end

    context 'when the project owner is not explicitly a member of the project' do
      before do
        project.members.find_by(user_id: project.namespace.owner.id).destroy!
      end

      it_behaves_like 'includes access level of the owner of the project as Maintainer'
    end
  end

  context 'direct members of the project' do
    it 'includes access levels of the direct members of the project' do
      developer = create(:project_member, :developer, source: project)
      maintainer = create(:project_member, :maintainer, source: project)

      expect(subject).to(
        include(
          hash_including(
            'user_id' => developer.user.id,
            'access_level' => Gitlab::Access::DEVELOPER
          ),
          hash_including(
            'user_id' => maintainer.user.id,
            'access_level' => Gitlab::Access::MAINTAINER
          )
        )
      )
    end

    it 'does not include access levels of users who have requested access to the project' do
      member_with_access_request = create(:project_member, :access_request, :developer, source: project)

      expect(subject).not_to(
        include(
          hash_including(
            'user_id' => member_with_access_request.user.id
          )
        )
      )
    end

    it 'includes access levels of users who are in non-active state' do
      blocked_member = create(:project_member, :blocked, :developer, source: project)

      expect(subject).to(
        include(
          hash_including(
            'user_id' => blocked_member.user.id,
            'access_level' => Gitlab::Access::DEVELOPER
          )
        )
      )
    end
  end

  context 'for a project within a group' do
    context 'project in a root group' do
      it 'includes access levels of users who are direct members of the parent group' do
        group_member = create(:group_member, :developer, source: group)

        expect(subject).to(
          include(
            hash_including(
              'user_id' => group_member.user.id,
              'access_level' => Gitlab::Access::DEVELOPER
            )
          )
        )
      end
    end

    context 'project in a subgroup' do
      let_it_be(:project) { create(:project, group: create(:group, :nested)) }

      it 'includes access levels of users who are members of the ancestors of the parent group' do
        group_member = create(:group_member, :maintainer, source: project.group.parent)

        expect(subject).to(
          include(
            hash_including(
              'user_id' => group_member.user.id,
              'access_level' => Gitlab::Access::MAINTAINER
            )
          )
        )
      end
    end

    context 'user is both a member of the project and a member of the parent group' do
      let_it_be(:user) { create(:user) }

      before do
        group.add_developer(user)
        project.add_maintainer(user)
      end

      it 'includes the maximum access level among project and group membership' do
        expect(subject).to(
          include(
            hash_including(
              'user_id' => user.id,
              'access_level' => Gitlab::Access::MAINTAINER
            )
          )
        )
      end
    end

    context 'members from group share' do
      let_it_be(:shared_with_group) { create(:group) }
      let_it_be(:user_from_shared_with_group) { create(:user) }

      before do
        shared_with_group.add_guest(user_from_shared_with_group)
        create(:group_group_link, :developer, shared_group: project.group, shared_with_group: shared_with_group)
      end

      it 'includes the user from the group share with the right access level' do
        expect(subject).to(
          include(
            hash_including(
              'user_id' => user_from_shared_with_group.id,
              'access_level' => Gitlab::Access::GUEST
            )
          )
        )
      end

      context 'when the project also has the same user as a member, but with a different access level' do
        before do
          project.add_maintainer(user_from_shared_with_group)
        end

        it 'includes the maximum access level among project and group membership' do
          expect(subject).to(
            include(
              hash_including(
                'user_id' => user_from_shared_with_group.id,
                'access_level' => Gitlab::Access::MAINTAINER
              )
            )
          )
        end
      end

      context "when the project's ancestor also has the same user as a member, but with a different access level" do
        before do
          project.group.add_maintainer(user_from_shared_with_group)
        end

        it 'includes the maximum access level among project and group membership' do
          expect(subject).to(
            include(
              hash_including(
                'user_id' => user_from_shared_with_group.id,
                'access_level' => Gitlab::Access::MAINTAINER
              )
            )
          )
        end
      end
    end
  end

  context 'for a project that is shared with other group(s)' do
    let_it_be(:shared_with_group) { create(:group) }
    let_it_be(:user_from_shared_with_group) { create(:user) }

    before do
      create(:project_group_link, :developer, project: project, group: shared_with_group)
      shared_with_group.add_maintainer(user_from_shared_with_group)
    end

    it 'includes the least among the specified access levels' do
      expect(subject).to(
        include(
          hash_including(
            'user_id' => user_from_shared_with_group.id,
            'access_level' => Gitlab::Access::DEVELOPER
          )
        )
      )
    end

    context 'when the group containing the project has forbidden group shares for any of its projects' do
      let_it_be(:project) { create(:project, group: create(:group)) }

      before do
        project.namespace.update!(share_with_group_lock: true)
      end

      it 'does not include the users from any group shares' do
        expect(subject).not_to(
          include(
            hash_including(
              'user_id' => user_from_shared_with_group.id
            )
          )
        )
      end
    end
  end

  context 'a combination of all possible avenues of membership' do
    let_it_be(:user) { create(:user) }
    let_it_be(:shared_with_group) { create(:group) }

    before do
      create(:project_group_link, :maintainer, project: project, group: shared_with_group)
      create(:group_group_link, :reporter, shared_group: project.group, shared_with_group: shared_with_group)

      shared_with_group.add_maintainer(user)
      group.add_guest(user)
      project.add_developer(user)
    end

    it 'includes the highest access level from all avenues of memberships' do
      expect(subject).to(
        include(
          hash_including(
            'user_id' => user.id,
            'access_level' => Gitlab::Access::MAINTAINER # From project_group_link
          )
        )
      )
    end
  end
end
