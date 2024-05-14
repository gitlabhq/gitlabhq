# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups (JavaScript fixtures)', feature_category: :groups_and_projects do
  include ApiHelpers
  include JavaScriptFixturesHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, name: 'frontend-fixtures-group', runners_token: 'runnerstoken:intabulasreferre') }
  let_it_be(:projects) { create_list(:project, 2, namespace: group) }

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

  describe API::Groups, '(JavaScript fixtures)', type: :request do
    before do
      group.add_owner(user)
      sign_in(user)
    end

    it 'api/groups/projects/get.json' do
      get api("/groups/#{group.id}/projects", user)

      expect(response).to be_successful
    end

    it 'api/groups/post.json' do
      post api("/groups", user), params: { name: 'frontend-fixtures-group-2', path: 'frontend-fixtures-group-2' }

      expect(response).to be_successful
    end
  end
end
