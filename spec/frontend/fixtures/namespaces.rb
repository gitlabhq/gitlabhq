# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Jobs (JavaScript fixtures)' do
  include ApiHelpers
  include JavaScriptFixturesHelpers
  include GraphqlHelpers

  describe API::Projects, type: :request do
    let_it_be(:user) { create(:user) }

    describe 'transfer_locations' do
      let_it_be(:groups) { create_list(:group, 4) }
      let_it_be(:project) { create(:project, namespace: user.namespace) }

      before_all do
        groups.each { |group| group.add_owner(user) }
      end

      it 'api/projects/transfer_locations_page_1.json' do
        get api("/projects/#{project.id}/transfer_locations?per_page=2", user)

        expect(response).to be_successful
      end

      it 'api/projects/transfer_locations_page_2.json' do
        get api("/projects/#{project.id}/transfer_locations?per_page=2&page=2", user)

        expect(response).to be_successful
      end
    end
  end

  describe API::Groups, type: :request do
    let_it_be(:user) { create(:user) }

    describe 'transfer_locations' do
      let_it_be(:groups) { create_list(:group, 4) }
      let_it_be(:transfer_from_group) { create(:group) }

      before_all do
        groups.each { |group| group.add_owner(user) }
        transfer_from_group.add_owner(user)
      end

      it 'api/groups/transfer_locations.json' do
        get api("/groups/#{transfer_from_group.id}/transfer_locations", user)

        expect(response).to be_successful
      end
    end
  end

  describe GraphQL::Query, type: :request do
    let_it_be(:user) { create(:user) }

    query_name = 'current_user_namespace.query.graphql'

    input_path = "projects/settings/graphql/queries/#{query_name}"
    output_path = "graphql/projects/settings/#{query_name}.json"

    it output_path do
      query = get_graphql_query_as_string(input_path)

      post_graphql(query, current_user: user)

      expect_graphql_errors_to_be_empty
    end
  end
end
