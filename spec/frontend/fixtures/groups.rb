# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups (JavaScript fixtures)', feature_category: :groups_and_projects do
  include ApiHelpers
  include JavaScriptFixturesHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, name: 'frontend-fixtures-group', runners_token: 'runnerstoken:intabulasreferre') }
  let_it_be(:projects) { create_list(:project, 2, namespace: group) }
  let_it_be(:shared_group) { create(:group) }
  let_it_be(:group_group_link) { create(:group_group_link, shared_group: shared_group, shared_with_group: group) }

  describe GroupsController, '(JavaScript fixtures)', type: :controller do
    render_views

    before do
      group.add_owner(user)
      sign_in(user)
    end

    it 'groups/edit.html' do
      get :edit, params: { id: group }

      expect(response).to be_successful
    end
  end

  describe Dashboard::GroupsController, '(JavaScript fixtures)', type: :controller do
    before do
      group.add_owner(user)
      sign_in(user)
    end

    it 'groups/dashboard/index.json' do
      get :index, format: :json

      expect(response).to be_successful
    end

    context 'when group has subgroups' do
      let_it_be(:subgroup) { create(:group, parent: group) }
      let_it_be(:nested_subgroup) { create(:group, parent: subgroup, name: 'foo bar baz') }

      it 'groups/dashboard/index_with_children.json' do
        get :index, format: :json, params: { filter: 'foo bar baz' }

        expect(response).to be_successful
      end
    end
  end

  describe Groups::ChildrenController, '(JavaScript fixtures)', type: :controller do
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:nested_subgroup) { create(:group, parent: subgroup, name: 'foo bar baz') }
    let_it_be(:project) { create(:project, namespace: subgroup) }
    let_it_be(:nested_project) { create(:project, namespace: nested_subgroup) }

    before do
      group.add_owner(user)
      sign_in(user)
    end

    it 'groups/children.json' do
      get :index, format: :json, params: { group_id: group.full_path, filter: 'project' }

      expect(response).to be_successful
    end
  end

  describe API::Groups, '(JavaScript fixtures)', type: :request do
    before do
      group.add_owner(user)
      sign_in(user)
    end

    it 'api/groups/projects/get.json' do
      get api("/groups/#{group.id}/projects", user)

      expect(response).to be_successful
    end

    it 'api/groups/groups/shared/get.json' do
      get api("/groups/#{group.id}/groups/shared", user)

      expect(response).to be_successful
    end

    it 'api/groups/post.json' do
      post api("/groups", user), params: { name: 'frontend-fixtures-group-2', path: 'frontend-fixtures-group-2' }

      expect(response).to be_successful
    end
  end
end
