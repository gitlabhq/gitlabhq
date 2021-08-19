# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProjectMembersHelper do
  include MembersPresentation

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }

  before do
    allow(helper).to receive(:current_user).and_return(current_user)
  end

  describe 'project members' do
    let_it_be(:members) { create_list(:project_member, 2, project: project) }
    let_it_be(:group_links) { create_list(:project_group_link, 1, project: project) }
    let_it_be(:invited) { create_list(:project_member, 2, :invited, project: project) }
    let_it_be(:access_requests) { create_list(:project_member, 2, :access_request, project: project) }

    let(:members_collection) { members }

    describe '#project_members_app_data_json' do
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
        project.add_maintainer(current_user)
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
