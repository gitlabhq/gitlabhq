# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProjectMembersHelper, feature_category: :groups_and_projects do
  include MembersPresentation

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, group: create(:group)) }

  before do
    allow(helper).to receive(:current_user).and_return(current_user)
  end

  describe 'project members' do
    let_it_be(:members) { create_list(:project_member, 2, project: project) }
    let_it_be(:invited) { create_list(:project_member, 2, :invited, project: project) }
    let_it_be(:access_requests) { create_list(:project_member, 2, :access_request, project: project) }
    let(:available_roles) do
      Gitlab::Access.options_with_owner.map { |name, access_level| { title: name, value: "static-#{access_level}" } }
    end

    let(:members_collection) { members }

    describe '#project_members_app_data_json' do
      subject do
        Gitlab::Json.parse(
          helper.project_members_app_data_json(
            project,
            members: present_members(members_collection),
            invited: present_members(invited),
            access_requests: present_members(access_requests),
            include_relations: [:inherited, :direct],
            search: nil,
            pending_members_count: nil
          )
        )
      end

      before do
        allow(helper).to receive(:project_project_member_path).with(project, ':id').and_return('/foo-bar/-/project_members/:id')
        project.add_maintainer(current_user)
      end

      it 'returns expected json' do
        expected = {
          source_id: project.id,
          can_manage_members: true,
          can_manage_access_requests: true,
          group_name: project.group.name,
          group_path: project.group.path,
          project_path: project.full_path,
          can_approve_access_requests: true,
          available_roles: available_roles
        }.as_json

        expect(subject).to include(expected)
      end

      it 'sets `members` property that matches json schema' do
        expect(subject['user']['members'].to_json).to match_schema('members')
      end

      it 'sets `member_path` property' do
        expect(subject['user']['member_path']).to eq('/foo-bar/-/project_members/:id')
      end

      context 'when pagination is not available' do
        it 'sets `pagination` attribute to expected json' do
          expected = {
            current_page: nil,
            per_page: nil,
            total_items: 2,
            param_name: nil,
            params: {}
          }.as_json

          expect(subject['invite']['pagination']).to include(expected)
        end
      end

      context 'when pagination is available' do
        let(:members_collection) { Kaminari.paginate_array(members).page(1).per(1) }

        it 'sets `pagination` attribute to expected json' do
          expected = {
            current_page: 1,
            per_page: 1,
            total_items: 2,
            param_name: :page,
            params: { search_groups: nil }
          }.as_json

          expect(subject['user']['pagination']).to match(expected)
        end
      end

      context 'group links' do
        let_it_be(:shared_with_group) { create(:group) }
        let_it_be(:group_link) { create(:project_group_link, project: project, group: shared_with_group) }

        before do
          allow(helper).to receive(:project_group_link_path).with(project, ':id').and_return('/foo-group/foo-project/-/group_links/:id')
        end

        it 'sets `group.members` property that matches json schema' do
          expect(subject['group']['members'].to_json).to match_schema('group_link/project_group_links')
        end

        it 'sets `member_path` property' do
          expect(subject['group']['member_path']).to eq('/foo-group/foo-project/-/group_links/:id')
        end

        context 'inherited' do
          let_it_be(:shared_with_group_1) { create(:group) }
          let_it_be(:shared_with_group_2) { create(:group) }
          let_it_be(:shared_with_group_3) { create(:group) }
          let_it_be(:shared_with_group_4) { create(:group) }
          let_it_be(:shared_with_group_5) { create(:group) }
          let_it_be(:top_group) { create(:group) }
          let_it_be(:sub_group) { create(:group, parent: top_group) }
          let_it_be(:project) { create(:project, group: sub_group) }
          let_it_be(:members) { create_list(:project_member, 2, project: project) }
          let_it_be(:invited) { create_list(:project_member, 2, :invited, project: project) }
          let_it_be(:access_requests) { create_list(:project_member, 2, :access_request, project: project) }
          let_it_be(:group_link_1) { create(:group_group_link, shared_group: top_group, shared_with_group: shared_with_group_1, group_access: Gitlab::Access::GUEST) }
          let_it_be(:group_link_2) { create(:group_group_link, shared_group: top_group, shared_with_group: shared_with_group_4, group_access: Gitlab::Access::GUEST) }
          let_it_be(:group_link_3) { create(:group_group_link, shared_group: top_group, shared_with_group: shared_with_group_5, group_access: Gitlab::Access::DEVELOPER) }
          let_it_be(:group_link_4) { create(:group_group_link, shared_group: sub_group, shared_with_group: shared_with_group_2, group_access: Gitlab::Access::DEVELOPER) }
          let_it_be(:group_link_5) { create(:group_group_link, shared_group: sub_group, shared_with_group: shared_with_group_4, group_access: Gitlab::Access::DEVELOPER) }
          let_it_be(:group_link_6) { create(:group_group_link, shared_group: sub_group, shared_with_group: shared_with_group_5, group_access: Gitlab::Access::GUEST) }
          let_it_be(:group_link_7) { create(:project_group_link, project: project, group: shared_with_group_1, group_access: Gitlab::Access::DEVELOPER) }
          let_it_be(:group_link_8) { create(:project_group_link, project: project, group: shared_with_group_2, group_access: Gitlab::Access::GUEST) }
          let_it_be(:group_link_9) { create(:project_group_link, project: project, group: shared_with_group_3, group_access: Gitlab::Access::REPORTER) }

          subject do
            Gitlab::Json.parse(
              helper.project_members_app_data_json(
                project,
                members: present_members(members_collection),
                invited: present_members(invited),
                access_requests: present_members(access_requests),
                include_relations: include_relations,
                search: nil,
                pending_members_count: nil
              )
            )
          end

          using RSpec::Parameterized::TableSyntax

          where(:include_relations, :result) do
            [:inherited, :direct] | lazy { [group_link_7, group_link_4, group_link_9, group_link_5, group_link_3].map(&:id) }
            [:inherited] | lazy { [group_link_1, group_link_4, group_link_5, group_link_3].map(&:id) }
            [:direct] | lazy { [group_link_7, group_link_8, group_link_9].map(&:id) }
          end

          with_them do
            it 'returns correct group links' do
              expect(subject['group']['members'].map { |link| link['id'] }).to match_array(result)
            end
          end
        end
      end
    end
  end

  describe '#project_member_header_subtext' do
    before do
      allow(helper).to receive(:can?).with(current_user, :admin_project_member, project).and_return(can_admin_member)
    end

    context 'when user can admin project members' do
      let(:can_admin_member) { true }

      before do
        assign(:project, project)
      end

      it 'contains expected text' do
        expect(helper.project_member_header_subtext(project)).to match('You can invite a new member to')
      end
    end

    context 'when user cannot admin project members' do
      let(:can_admin_member) { false }

      it 'contains expected text' do
        expect(helper.project_member_header_subtext(project)).to match('Members can be added by project')
      end
    end
  end
end
