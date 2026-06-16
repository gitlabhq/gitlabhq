# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin (GraphQL fixtures)', feature_category: :organization do
  describe GraphQL::Query, type: :request do
    include GraphqlHelpers
    include JavaScriptFixturesHelpers

    let_it_be(:current_user, freeze: false) { create(:user, :admin) }
    let_it_be(:owner, freeze: false) { create(:user) }
    let_it_be(:groups, freeze: false) do
      create_list(:group, 3, :with_avatar, owners: [owner, current_user], description: 'foo bar')
    end

    let_it_be(:pending_deletion_group, freeze: false) do
      create(:group_with_deletion_schedule, :deletion_scheduled, owners: [owner, current_user])
    end

    let_it_be(:projects, freeze: false) do
      create_list(:project, 3, :with_avatar, owners: [owner, current_user], description: 'foo bar')
    end

    let_it_be(:pending_deletion_project, freeze: false) do
      create(:project, :aimed_for_deletion, owners: [owner, current_user])
    end

    let_it_be(:project, freeze: false) do
      create(:project,
        namespace: groups.first,
        statistics: build(
          :project_statistics,
          namespace: groups.first,
          storage_size: 100.megabytes
        )
      )
    end

    before do
      sign_in(current_user)
    end

    describe 'groups' do
      base_input_path = 'admin/groups/index/graphql/queries/'
      base_output_path = 'graphql/admin/'
      query_name = 'admin_groups.query.graphql'

      it "#{base_output_path}#{query_name}.json" do
        query = get_graphql_query_as_string("#{base_input_path}#{query_name}")

        post_graphql(
          query,
          current_user: current_user,
          variables: { search: '', first: 3, sort: 'created_at_asc', active: true }
        )

        expect_graphql_errors_to_be_empty
      end

      it "#{base_output_path}inactive_#{query_name}.json" do
        query = get_graphql_query_as_string("#{base_input_path}#{query_name}")

        post_graphql(
          query,
          current_user: current_user,
          variables: { search: '', first: 3, sort: 'created_at_asc', active: false }
        )

        expect_graphql_errors_to_be_empty
      end
    end

    describe 'projects' do
      base_input_path = 'admin/projects/index/graphql/queries/'
      base_output_path = 'graphql/admin/'
      query_name = 'admin_projects.query.graphql'

      it "#{base_output_path}#{query_name}.json" do
        query = get_graphql_query_as_string("#{base_input_path}#{query_name}")

        post_graphql(
          query,
          current_user: current_user,
          variables: { search: '', first: 3, sort: 'created_at_asc', active: true }
        )

        expect_graphql_errors_to_be_empty
      end

      it "#{base_output_path}inactive_#{query_name}.json" do
        query = get_graphql_query_as_string("#{base_input_path}#{query_name}")

        post_graphql(
          query,
          current_user: current_user,
          variables: { search: '', first: 3, sort: 'created_at_asc', active: false }
        )

        expect_graphql_errors_to_be_empty
      end
    end
  end
end
