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
    let_it_be(:links) { ::Members::GroupLinksCollection.new([]) }
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
            links: links,
            access_requests: present_members(access_requests),
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
        let_it_be(:project_group_link) { create(:project_group_link, project: project, group: shared_with_group) }
        let_it_be(:group_group_link) { create(:group_group_link, shared_group: shared_with_group) }

        let_it_be(:links) do
          ::Members::GroupLinksCollection.new([group_group_link, project_group_link])
        end

        before do
          allow(helper).to receive(:project_group_link_path).with(project, ':id').and_return('/foo-group/foo-project/-/group_links/:id')
        end

        it 'sets `group.members` property' do
          serialized_members = project_group_links_serialized(project, links.project_links)
          serialized_members += group_group_links_serialized(project, links.group_links)

          expect(subject['group']['members']).to eq(serialized_members.map(&:as_json))
        end

        it 'sets `group.pagination` property' do
          expect(subject['group']['pagination']).to eq({
            'current_page' => 1,
            'param_name' => 'page',
            'params' => {},
            'per_page' => 20,
            'total_items' => 2
          })
        end

        it 'sets `member_path` property' do
          expect(subject['group']['member_path']).to eq('/foo-group/foo-project/-/group_links/:id')
        end
      end
    end
  end

  describe '#project_member_header_subtext' do
    before do
      allow(helper).to receive(:can?).with(current_user, :invite_project_members, project).and_return(true)
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
