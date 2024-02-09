# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Achievements (JavaScript fixtures)', feature_category: :user_profile do
  include JavaScriptFixturesHelpers
  include ApiHelpers

  describe GraphQL::Query, type: :request do
    include GraphqlHelpers

    let_it_be(:group) { create(:group, :public) }

    let(:query_path) { 'achievements/components/graphql/get_group_achievements.query.graphql' }
    let(:query) { get_graphql_query_as_string(query_path) }

    it "graphql/get_group_achievements_empty_response.json" do
      post_graphql(query, current_user: nil, variables: { group_full_path: group.full_path })

      expect_graphql_errors_to_be_empty
    end

    context 'with achievements' do
      before_all do
        create(:achievement, namespace: group, name: "Hero")
        create(:achievement, namespace: group, name: "Star")
        create(:achievement, namespace: group, name: "Legend")
      end

      it "graphql/get_group_achievements_response.json" do
        post_graphql(query, current_user: nil, variables: { group_full_path: group.full_path })

        expect_graphql_errors_to_be_empty
      end

      it "graphql/get_group_achievements_paginated_response.json" do
        post_graphql(query, current_user: nil, variables: { group_full_path: group.full_path, first: 2 })

        expect_graphql_errors_to_be_empty
      end
    end
  end
end
