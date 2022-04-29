# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::SharedProjectsController do
  def get_shared_projects(params = {})
    get :index, params: params.reverse_merge(format: :json, group_id: group.full_path)
  end

  def share_project(project)
    group.add_developer(user)

    Projects::GroupLinks::CreateService.new(
      project,
      group,
      user,
      link_group_access: Gitlab::Access::DEVELOPER
    ).execute
  end

  let!(:group) { create(:group) }
  let!(:user) { create(:user) }
  let!(:shared_project) do
    shared_project = create(:project, namespace: user.namespace)
    share_project(shared_project)

    shared_project
  end

  let(:json_project_ids) { json_response.map { |project_info| project_info['id'] } }

  before do
    sign_in(user)
  end

  describe 'GET #index' do
    it 'returns only projects shared with the group' do
      create(:project, namespace: group)

      get_shared_projects

      expect(json_project_ids).to contain_exactly(shared_project.id)
    end

    it 'allows filtering shared projects' do
      project = create(:project, namespace: user.namespace, name: "Searching for")
      share_project(project)

      get_shared_projects(filter: 'search')

      expect(json_project_ids).to contain_exactly(project.id)
    end

    it 'allows sorting projects' do
      shared_project.update!(name: 'bbb')
      second_project = create(:project, namespace: user.namespace, name: 'aaaa')
      share_project(second_project)

      get_shared_projects(sort: 'name_asc')

      expect(json_project_ids).to eq([second_project.id, shared_project.id])
    end

    it 'does not include archived projects' do
      archived_project = create(:project, :archived, namespace: user.namespace)
      share_project(archived_project)

      get_shared_projects

      expect(json_project_ids).to contain_exactly(shared_project.id)
    end
  end
end
