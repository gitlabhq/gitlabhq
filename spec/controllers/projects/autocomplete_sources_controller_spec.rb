# frozen_string_literal: true

require 'spec_helper'

describe Projects::AutocompleteSourcesController do
  set(:group) { create(:group) }
  set(:project) { create(:project, namespace: group) }
  set(:issue) { create(:issue, project: project) }
  set(:user) { create(:user) }

  describe 'GET members' do
    before do
      group.add_owner(user)
      sign_in(user)
    end

    it 'returns an array of member object' do
      get :members, format: :json, params: { namespace_id: group.path, project_id: project.path, type: issue.class.name, type_id: issue.id }

      all = json_response.find {|member| member["username"] == 'all'}
      the_group = json_response.find {|member| member["username"] == group.full_path}
      the_user = json_response.find {|member| member["username"] == user.username}

      expect(all.symbolize_keys).to include(username: 'all',
                                            name: 'All Project and Group Members',
                                            count: 1)

      expect(the_group.symbolize_keys).to include(type: group.class.name,
                                                  name: group.full_name,
                                                  avatar_url: group.avatar_url,
                                                  count: 1)

      expect(the_user.symbolize_keys).to include(type: user.class.name,
                                                 name: user.name,
                                                 avatar_url: user.avatar_url)
    end
  end

  describe 'GET milestones' do
    let(:group) { create(:group, :public) }
    let(:project) { create(:project, :public, namespace: group) }
    let!(:project_milestone) { create(:milestone, project: project) }
    let!(:group_milestone) { create(:milestone, group: group) }

    before do
      sign_in(user)
    end

    it 'lists milestones' do
      group.add_owner(user)

      get :milestones, format: :json, params: { namespace_id: group.path, project_id: project.path }

      milestone_titles = json_response.map { |milestone| milestone["title"] }
      expect(milestone_titles).to match_array([project_milestone.title, group_milestone.title])
    end

    context 'when user cannot read project issues and merge requests' do
      it 'renders 404' do
        project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
        project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)

        get :milestones, format: :json, params: { namespace_id: group.path, project_id: project.path }

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
