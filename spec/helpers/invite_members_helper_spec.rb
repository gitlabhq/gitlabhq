# frozen_string_literal: true

require "spec_helper"

RSpec.describe InviteMembersHelper do
  include Devise::Test::ControllerHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group, projects: [project]) }
  let_it_be(:developer) { create(:user, developer_of: project) }

  let_it_be(:owner) { create(:user, owner_of: project) }

  describe '#common_invite_group_modal_data' do
    context 'when current user is an owner' do
      before do
        allow(helper).to receive(:current_user).and_return(owner)
      end

      it 'has expected common attributes' do
        attributes = {
          id: project.id,
          root_id: project.root_ancestor.id,
          name: project.name,
          default_access_level: Gitlab::Access::GUEST,
          invalid_groups: project.related_group_ids,
          help_link: help_page_url('user/permissions.md'),
          is_project: 'true',
          access_levels: Gitlab::Access.options_with_owner.to_json,
          full_path: project.full_path
        }

        expect(helper.common_invite_group_modal_data(project, ProjectMember)).to include(attributes)
      end
    end

    context 'when sharing with groups outside the hierarchy is disabled' do
      let_it_be(:group) { create(:group) }

      before do
        group.update!(prevent_sharing_groups_outside_hierarchy: true)
      end

      it 'provides the correct attributes' do
        expect(helper.common_invite_group_modal_data(group, GroupMember))
          .to include({ groups_filter: 'descendant_groups', parent_id: group.id })
      end
    end

    context 'when invite_to_root_group feature flag is enabled' do
      before do
        stub_feature_flags(invite_to_root_group: true)
        allow(helper).to receive_messages(current_user: current_user, can?: false)
      end

      context 'when user is Owner of the root group' do
        let(:current_user) { owner }

        it 'includes root group invite attributes' do
          allow(helper).to receive(:can?).with(owner, :invite_group_members, project.root_ancestor).and_return(true)

          result = helper.common_invite_group_modal_data(project, ProjectMember)

          expect(result[:root_group_name]).to eq(project.root_ancestor.name)
          expect(result[:is_top_level_group]).to eq('false')
          expect(result[:can_invite_to_root_group]).to eq('true')
        end

        context 'when source is the root group' do
          it 'returns is_top_level_group as true' do
            result = helper.common_invite_group_modal_data(group, GroupMember)

            expect(result[:is_top_level_group]).to eq('true')
          end
        end
      end

      context 'when user is NOT Owner of the root group' do
        let(:current_user) { developer }

        it 'returns can_invite_to_root_group as false' do
          allow(helper).to receive(:can?).with(developer, :invite_group_members,
            project.root_ancestor).and_return(false)

          result = helper.common_invite_group_modal_data(project, ProjectMember)

          expect(result[:can_invite_to_root_group]).to eq('false')
        end
      end
    end

    context 'when sharing with groups outside the hierarchy is enabled' do
      before do
        group.update!(prevent_sharing_groups_outside_hierarchy: false)
      end

      it 'does not return filter attributes' do
        expect(helper.common_invite_group_modal_data(project.group, ProjectMember).keys)
          .not_to include(:groups_filter, :parent_id)
      end
    end
  end

  describe '#common_invite_modal_dataset' do
    it 'has expected common attributes' do
      attributes = {
        id: project.id,
        root_id: project.root_ancestor.id,
        name: project.name,
        default_access_level: Gitlab::Access::GUEST,
        full_path: project.full_path
      }

      expect(helper.common_invite_modal_dataset(project)).to include(attributes)
    end

    context 'when invite_to_root_group feature flag is enabled' do
      before do
        stub_feature_flags(invite_to_root_group: true)
        allow(helper).to receive_messages(current_user: current_user, can?: false)
      end

      context 'when user is Owner of the root group' do
        let(:current_user) { owner }

        it 'returns can_invite_to_root_group as true' do
          allow(helper).to receive(:can?).with(owner, :invite_group_members, project.root_ancestor).and_return(true)

          result = helper.common_invite_modal_dataset(project)

          expect(result[:can_invite_to_root_group]).to eq('true')
          expect(result[:root_group_name]).to eq(project.root_ancestor.name)
        end

        context 'when source is the root group' do
          it 'returns is_top_level_group as true' do
            result = helper.common_invite_modal_dataset(group)

            expect(result[:is_top_level_group]).to eq('true')
          end
        end

        context 'when source is a project' do
          it 'returns is_top_level_group as false' do
            result = helper.common_invite_modal_dataset(project)

            expect(result[:is_top_level_group]).to eq('false')
          end
        end
      end

      context 'when user is NOT Owner of the root group' do
        let(:current_user) { developer }

        it 'returns can_invite_to_root_group as false' do
          allow(helper).to receive(:can?).with(developer, :invite_group_members,
            project.root_ancestor).and_return(false)

          result = helper.common_invite_modal_dataset(project)

          expect(result[:can_invite_to_root_group]).to eq('false')
        end
      end
    end
  end

  context 'with project' do
    before do
      allow(helper).to receive(:current_user) { owner }
      assign(:project, project)
    end

    describe "#can_invite_members_for_project?" do
      context 'when the user can_invite_project_members' do
        before do
          allow(helper).to receive(:can?).with(owner, :invite_project_members, project).and_return(true)
        end

        it 'returns true', :aggregate_failures do
          expect(helper.can_invite_members_for_project?(project)).to eq true
          expect(helper).to have_received(:can?).with(owner, :invite_project_members, project)
        end
      end

      context 'when the user can not manage project members' do
        it 'returns false' do
          expect(helper).to receive(:can?).with(owner, :invite_project_members, project).and_return(false)

          expect(helper.can_invite_members_for_project?(project)).to eq false
        end
      end
    end
  end

  describe '#invite_accepted_notice' do
    context 'for group invites' do
      let_it_be(:group) { create(:group, name: 'My group') }
      let_it_be(:member) { build(:group_member, :guest, group: group) }

      it 'returns the expected message' do
        expect(helper.invite_accepted_notice(member))
          .to eq('You have been granted access to the My group group with the following role: Guest.')
      end
    end

    context 'for project invites' do
      let_it_be(:project) { create(:project, name: 'My project') }
      let_it_be(:member) { build(:project_member, :guest, project: project) }

      it 'returns the expected message' do
        expect(helper.invite_accepted_notice(member))
          .to eq('You have been granted access to the My project project with the following role: Guest.')
      end
    end
  end
end
