require 'spec_helper'

describe 'Project > Members > Invite group and members', :js do
  include Select2Helper
  include ActionView::Helpers::DateHelper

  let(:maintainer) { create(:user) }

  describe 'Share group lock' do
    shared_examples 'the project cannot be shared with groups' do
      it 'user is only able to share with members' do
        visit project_settings_members_path(project)

        expect(page).not_to have_selector('#invite-member-tab')
        expect(page).not_to have_selector('#invite-group-tab')
        expect(page).not_to have_selector('.invite-group')
        expect(page).to have_selector('.invite-member')
      end
    end

    shared_examples 'the project cannot be shared with members' do
      it 'user is only able to share with groups' do
        visit project_settings_members_path(project)

        expect(page).not_to have_selector('#invite-member-tab')
        expect(page).not_to have_selector('#invite-group-tab')
        expect(page).not_to have_selector('.invite-member')
        expect(page).to have_selector('.invite-group')
      end
    end

    shared_examples 'the project cannot be shared with groups and members' do
      it 'no tabs or share content exists' do
        visit project_settings_members_path(project)

        expect(page).not_to have_selector('#invite-member-tab')
        expect(page).not_to have_selector('#invite-group-tab')
        expect(page).not_to have_selector('.invite-member')
        expect(page).not_to have_selector('.invite-group')
      end
    end

    shared_examples 'the project can be shared with groups and members' do
      it 'both member and group tabs exist' do
        visit project_settings_members_path(project)

        expect(page).not_to have_selector('.invite-member')
        expect(page).not_to have_selector('.invite-group')
        expect(page).to have_selector('#invite-member-tab')
        expect(page).to have_selector('#invite-group-tab')
      end
    end

    context 'for a project in a root group' do
      let!(:group_to_share_with) { create(:group) }
      let(:project) { create(:project, namespace: create(:group)) }

      before do
        project.add_maintainer(maintainer)
        sign_in(maintainer)
      end

      context 'when the group has "Share with group lock" and "Member lock" disabled' do
        it_behaves_like 'the project can be shared with groups and members'

        it 'the project can be shared with another group' do
          visit project_settings_members_path(project)

          click_on 'invite-group-tab'

          select2 group_to_share_with.id, from: '#link_group_id'
          page.find('body').click
          find('.btn-create').click

          page.within('.project-members-groups') do
            expect(page).to have_content(group_to_share_with.name)
          end
        end
      end

      context 'when the group has "Share with group lock" enabled' do
        before do
          project.namespace.update_column(:share_with_group_lock, true)
        end

        it_behaves_like 'the project cannot be shared with groups'
      end

      context 'when the group has membership lock enabled' do
        before do
          project.namespace.update_column(:membership_lock, true)
        end

        it_behaves_like 'the project cannot be shared with members'
      end

      context 'when the group has membership lock and "Share with group lock" enabled' do
        before do
          project.namespace.update(share_with_group_lock: true, membership_lock: true)
        end

        it_behaves_like 'the project cannot be shared with groups and members'
      end
    end

    context 'for a project in a subgroup', :nested_groups do
      let(:root_group) { create(:group) }
      let(:subgroup) { create(:group, parent: root_group) }
      let(:project) { create(:project, namespace: subgroup) }

      before do
        project.add_maintainer(maintainer)
        sign_in(maintainer)
      end

      context 'when the root_group has "Share with group lock" and membership lock disabled' do
        context 'when the subgroup has "Share with group lock" and membership lock disabled' do
          it_behaves_like 'the project can be shared with groups and members'
        end

        context 'when the subgroup has "Share with group lock" enabled' do
          before do
            subgroup.update_column(:share_with_group_lock, true)
          end

          it_behaves_like 'the project cannot be shared with groups'
        end

        context 'when the subgroup has membership lock enabled' do
          before do
            subgroup.update_column(:membership_lock, true)
          end

          it_behaves_like 'the project cannot be shared with members'
        end

        context 'when the group has membership lock and "Share with group lock" enabled' do
          before do
            subgroup.update(share_with_group_lock: true, membership_lock: true)
          end

          it_behaves_like 'the project cannot be shared with groups and members'
        end
      end

      context 'when the root_group has "Share with group lock" and membership lock enabled' do
        before do
          root_group.update(share_with_group_lock: true, membership_lock: true)
          subgroup.reload
        end

        # This behaviour should be changed to disable sharing with members as well
        # See: https://gitlab.com/gitlab-org/gitlab-ce/issues/42093
        it_behaves_like 'the project cannot be shared with groups'

        context 'when the subgroup has "Share with group lock" and membership lock disabled (parent overridden)' do
          before do
            subgroup.update(share_with_group_lock: false, membership_lock: false)
          end

          it_behaves_like 'the project can be shared with groups and members'
        end

        # This behaviour should be changed to disable sharing with members as well
        # See: https://gitlab.com/gitlab-org/gitlab-ce/issues/42093
        context 'when the subgroup has membership lock enabled (parent overridden)' do
          before do
            subgroup.update_column(:membership_lock, true)
          end

          it_behaves_like 'the project cannot be shared with groups and members'
        end

        context 'when the subgroup has "Share with group lock" enabled (parent overridden)' do
          before do
            subgroup.update_column(:share_with_group_lock, true)
          end

          it_behaves_like 'the project cannot be shared with groups'
        end

        context 'when the subgroup has "Share with group lock" and membership lock enabled' do
          before do
            subgroup.update(membership_lock: true, share_with_group_lock: true)
          end

          it_behaves_like 'the project cannot be shared with groups and members'
        end
      end
    end
  end
end
