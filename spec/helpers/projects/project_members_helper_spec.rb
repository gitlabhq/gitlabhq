# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProjectMembersHelper, feature_category: :groups_and_projects do
  include MembersPresentation

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project, freeze: false) { create(:project, group: create(:group)) }

  before do
    allow(helper).to receive(:current_user).and_return(current_user)
  end

  # These examples cover the helper's wiring: serializer construction, params
  # plumbing and JSON rendering.
  describe '#project_members_app_data_json' do
    let_it_be(:links, freeze: false) { ::Members::GroupLinksCollection.new([]) }
    let_it_be(:members) { create_list(:project_member, 2, project: project) }
    let_it_be(:invited) { create_list(:project_member, 2, :invited, project: project) }
    let_it_be(:access_requests) { create_list(:project_member, 2, :access_request, project: project) }

    let(:available_roles) do
      Gitlab::Access.options_with_owner.map { |name, access_level| { title: name, value: "static-#{access_level}" } }
    end

    subject do
      Gitlab::Json.parse(
        helper.project_members_app_data_json(
          project,
          members: present_members(members),
          invited: present_members(invited),
          links: links,
          access_requests: present_members(access_requests),
          pending_members_count: nil
        )
      )
    end

    before_all do
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

    context 'when a direct members search param is present' do
      let(:searched_member) { members.first }

      before do
        allow(helper).to receive(:params).and_return(
          ActionController::Parameters.new(search_direct_members: searched_member.user.name)
        )
      end

      it 'passes the filter params to the serializer and seeds the filtered count' do
        expect(subject['direct_members']['pagination']['total_items']).to eq(1)
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
