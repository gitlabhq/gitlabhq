# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Runner (JavaScript fixtures)' do
  include AdminModeHelper
  include ApiHelpers
  include JavaScriptFixturesHelpers
  include GraphqlHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, :public) }

  let_it_be(:instance_runner) { create(:ci_runner, :instance, version: '1.0.0', revision: '123', description: 'Instance runner', ip_address: '127.0.0.1') }
  let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group], active: false, version: '2.0.0', revision: '456', description: 'Group runner', ip_address: '127.0.0.1') }
  let_it_be(:group_runner_2) { create(:ci_runner, :group, groups: [group], active: false, version: '2.0.0', revision: '456', description: 'Group runner 2', ip_address: '127.0.0.1') }
  let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project], active: false, version: '2.0.0', revision: '456', description: 'Project runner', ip_address: '127.0.0.1') }

  query_path = 'runner/graphql/'
  fixtures_path = 'graphql/runner/'

  after(:all) do
    remove_repository(project)
  end

  describe GraphQL::Query, type: :request do
    get_runners_query_name = 'get_runners.query.graphql'

    before do
      sign_in(admin)
      enable_admin_mode!(admin)
    end

    let_it_be(:query) do
      get_graphql_query_as_string("#{query_path}#{get_runners_query_name}")
    end

    it "#{fixtures_path}#{get_runners_query_name}.json" do
      post_graphql(query, current_user: admin, variables: {})

      expect_graphql_errors_to_be_empty
    end

    it "#{fixtures_path}#{get_runners_query_name}.paginated.json" do
      post_graphql(query, current_user: admin, variables: { first: 2 })

      expect_graphql_errors_to_be_empty
    end
  end

  describe GraphQL::Query, type: :request do
    get_runners_count_query_name = 'get_runners_count.query.graphql'

    before do
      sign_in(admin)
      enable_admin_mode!(admin)
    end

    let_it_be(:query) do
      get_graphql_query_as_string("#{query_path}#{get_runners_count_query_name}")
    end

    it "#{fixtures_path}#{get_runners_count_query_name}.json" do
      post_graphql(query, current_user: admin, variables: {})

      expect_graphql_errors_to_be_empty
    end
  end

  describe GraphQL::Query, type: :request do
    get_runner_query_name = 'get_runner.query.graphql'

    before do
      sign_in(admin)
      enable_admin_mode!(admin)
    end

    let_it_be(:query) do
      get_graphql_query_as_string("#{query_path}#{get_runner_query_name}")
    end

    it "#{fixtures_path}#{get_runner_query_name}.json" do
      post_graphql(query, current_user: admin, variables: {
        id: instance_runner.to_global_id.to_s
      })

      expect_graphql_errors_to_be_empty
    end
  end

  describe GraphQL::Query, type: :request do
    get_group_runners_query_name = 'get_group_runners.query.graphql'

    let_it_be(:group_owner) { create(:user) }

    before do
      group.add_owner(group_owner)
    end

    let_it_be(:query) do
      get_graphql_query_as_string("#{query_path}#{get_group_runners_query_name}")
    end

    it "#{fixtures_path}#{get_group_runners_query_name}.json" do
      post_graphql(query, current_user: group_owner, variables: {
        groupFullPath: group.full_path
      })

      expect_graphql_errors_to_be_empty
    end

    it "#{fixtures_path}#{get_group_runners_query_name}.paginated.json" do
      post_graphql(query, current_user: group_owner, variables: {
        groupFullPath: group.full_path,
        first: 1
      })

      expect_graphql_errors_to_be_empty
    end
  end
end
