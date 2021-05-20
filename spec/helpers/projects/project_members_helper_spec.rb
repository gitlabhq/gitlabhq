# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProjectMembersHelper do
  include MembersPresentation

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:allow_admin_project) { nil }

  before do
    allow(helper).to receive(:current_user).and_return(current_user)
    allow(helper).to receive(:can?).with(current_user, :admin_project_member, project).and_return(allow_admin_project)
  end

  shared_examples 'when `current_user` does not have `admin_project_member` permissions' do
    let(:allow_admin_project) { false }

    it { is_expected.to be(false) }
  end

  describe '#can_manage_project_members?' do
    subject { helper.can_manage_project_members?(project) }

    context 'when `current_user` has `admin_project_member` permissions' do
      let(:allow_admin_project) { true }

      it { is_expected.to be(true) }
    end

    include_examples 'when `current_user` does not have `admin_project_member` permissions'
  end

  describe '#show_groups?' do
    subject { helper.show_groups?(project.project_group_links) }

    context 'when group links exist' do
      let!(:project_group_link) { create(:project_group_link, project: project) }

      it { is_expected.to be(true) }
    end

    context 'when `search_groups` param is set' do
      before do
        allow(helper).to receive(:params).and_return({ search_groups: 'foo' })
      end

      it { is_expected.to be(true) }
    end

    context 'when `search_groups` param is not set and group links do not exist' do
      it { is_expected.to be(false) }
    end
  end

  describe '#show_invited_members?' do
    subject { helper.show_invited_members?(project, project.project_members.invite) }

    context 'when `current_user` has `admin_project_member` permissions' do
      let(:allow_admin_project) { true }

      context 'when invited members exist' do
        let!(:invite) { create(:project_member, :invited, project: project) }

        it { is_expected.to be(true) }
      end

      context 'when invited members do not exist' do
        it { is_expected.to be(false) }
      end
    end

    include_examples 'when `current_user` does not have `admin_project_member` permissions'
  end

  describe '#show_access_requests?' do
    subject { helper.show_access_requests?(project, project.requesters) }

    context 'when `current_user` has `admin_project_member` permissions' do
      let(:allow_admin_project) { true }

      context 'when access requests exist' do
        let!(:access_request) { create(:project_member, :access_request, project: project) }

        it { is_expected.to be(true) }
      end

      context 'when access requests do not exist' do
        it { is_expected.to be(false) }
      end
    end

    include_examples 'when `current_user` does not have `admin_project_member` permissions'
  end

  describe '#groups_tab_active?' do
    subject { helper.groups_tab_active? }

    context 'when `search_groups` param is set' do
      before do
        allow(helper).to receive(:params).and_return({ search_groups: 'foo' })
      end

      it { is_expected.to be(true) }
    end

    context 'when `search_groups` param is not set' do
      it { is_expected.to be(false) }
    end
  end

  describe '#current_user_is_group_owner?' do
    let(:group) { create(:group) }

    subject { helper.current_user_is_group_owner?(project2) }

    describe "when current user is the owner of the project's parent group" do
      let(:project2) { create(:project, namespace: group) }

      before do
        group.add_owner(current_user)
      end

      it { is_expected.to be(true) }
    end

    describe "when current user is not the owner of the project's parent group" do
      let_it_be(:user) { create(:user) }

      let(:project2) { create(:project, namespace: group) }

      before do
        group.add_owner(user)
      end

      it { is_expected.to be(false) }
    end

    describe "when project does not have a parent group" do
      let(:user) { create(:user) }
      let(:project2) { create(:project, namespace: user.namespace) }

      it { is_expected.to be(false) }
    end
  end

  describe 'project members' do
    let_it_be(:members) { create_list(:project_member, 2, project: project) }
    let_it_be(:group_links) { create_list(:project_group_link, 1, project: project) }
    let_it_be(:invited) { create_list(:project_member, 2, :invited, project: project) }
    let_it_be(:access_requests) { create_list(:project_member, 2, :access_request, project: project) }

    let(:members_collection) { members }

    describe '#project_members_app_data_json' do
      let(:allow_admin_project) { true }

      subject do
        Gitlab::Json.parse(
          helper.project_members_app_data_json(
            project,
            members: present_members(members_collection),
            group_links: group_links,
            invited: present_members(invited),
            access_requests: present_members(access_requests)
          )
        )
      end

      before do
        allow(helper).to receive(:project_project_member_path).with(project, ':id').and_return('/foo-bar/-/project_members/:id')
      end

      it 'returns expected json' do
        expected = {
          source_id: project.id,
          can_manage_members: true
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
    end
  end
end
