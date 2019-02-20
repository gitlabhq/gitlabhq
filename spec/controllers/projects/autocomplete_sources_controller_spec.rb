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
end
