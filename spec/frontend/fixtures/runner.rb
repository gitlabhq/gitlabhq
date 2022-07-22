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
  let_it_be(:project_2) { create(:project, :repository, :public) }

  let_it_be(:instance_runner) { create(:ci_runner, :instance, version: '1.0.0', description: 'Instance runner', ip_address: '127.0.0.1') }
  let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group], active: false, version: '2.0.0', description: 'Group runner', ip_address: '127.0.0.1') }
  let_it_be(:group_runner_2) { create(:ci_runner, :group, groups: [group], active: false, version: '2.0.0', description: 'Group runner 2', ip_address: '127.0.0.1') }
  let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project, project_2], active: false, version: '2.0.0', description: 'Project runner', ip_address: '127.0.0.1') }
  let_it_be(:build) { create(:ci_build, runner: instance_runner) }

  query_path = 'runner/graphql/'
  fixtures_path = 'graphql/runner/'

  after(:all) do
    remove_repository(project)
  end

  before do
    allow(Gitlab::Ci::RunnerUpgradeCheck.instance)
      .to receive(:check_runner_upgrade_suggestion)
      .and_return([nil, :not_available])
  end

  describe do
    before do
      sign_in(admin)
      enable_admin_mode!(admin)
    end

    describe GraphQL::Query, type: :request do
      all_runners_query = 'list/all_runners.query.graphql'

      let_it_be(:query) do
        get_graphql_query_as_string("#{query_path}#{all_runners_query}")
      end

      it "#{fixtures_path}#{all_runners_query}.json" do
        post_graphql(query, current_user: admin, variables: {})

        expect_graphql_errors_to_be_empty
      end

      it "#{fixtures_path}#{all_runners_query}.paginated.json" do
        post_graphql(query, current_user: admin, variables: { first: 2 })

        expect_graphql_errors_to_be_empty
      end
    end

    describe GraphQL::Query, type: :request do
      all_runners_count_query = 'list/all_runners_count.query.graphql'

      let_it_be(:query) do
        get_graphql_query_as_string("#{query_path}#{all_runners_count_query}")
      end

      it "#{fixtures_path}#{all_runners_count_query}.json" do
        post_graphql(query, current_user: admin, variables: {})

        expect_graphql_errors_to_be_empty
      end
    end

    describe GraphQL::Query, type: :request do
      runner_query = 'show/runner.query.graphql'

      let_it_be(:query) do
        get_graphql_query_as_string("#{query_path}#{runner_query}")
      end

      it "#{fixtures_path}#{runner_query}.json" do
        post_graphql(query, current_user: admin, variables: {
          id: instance_runner.to_global_id.to_s
        })

        expect_graphql_errors_to_be_empty
      end

      it "#{fixtures_path}#{runner_query}.with_group.json" do
        post_graphql(query, current_user: admin, variables: {
          id: group_runner.to_global_id.to_s
        })

        expect_graphql_errors_to_be_empty
      end
    end

    describe GraphQL::Query, type: :request do
      runner_projects_query = 'show/runner_projects.query.graphql'

      let_it_be(:query) do
        get_graphql_query_as_string("#{query_path}#{runner_projects_query}")
      end

      it "#{fixtures_path}#{runner_projects_query}.json" do
        post_graphql(query, current_user: admin, variables: {
          id: project_runner.to_global_id.to_s
        })

        expect_graphql_errors_to_be_empty
      end
    end

    describe GraphQL::Query, type: :request do
      runner_jobs_query = 'show/runner_jobs.query.graphql'

      let_it_be(:query) do
        get_graphql_query_as_string("#{query_path}#{runner_jobs_query}")
      end

      it "#{fixtures_path}#{runner_jobs_query}.json" do
        post_graphql(query, current_user: admin, variables: {
          id: instance_runner.to_global_id.to_s
        })

        expect_graphql_errors_to_be_empty
      end
    end

    describe GraphQL::Query, type: :request do
      runner_jobs_query = 'edit/runner_form.query.graphql'

      let_it_be(:query) do
        get_graphql_query_as_string("#{query_path}#{runner_jobs_query}")
      end

      it "#{fixtures_path}#{runner_jobs_query}.json" do
        post_graphql(query, current_user: admin, variables: {
          id: instance_runner.to_global_id.to_s
        })

        expect_graphql_errors_to_be_empty
      end
    end
  end

  describe do
    let_it_be(:group_owner) { create(:user) }

    before do
      group.add_owner(group_owner)
    end

    describe GraphQL::Query, type: :request do
      group_runners_query = 'list/group_runners.query.graphql'

      let_it_be(:query) do
        get_graphql_query_as_string("#{query_path}#{group_runners_query}")
      end

      it "#{fixtures_path}#{group_runners_query}.json" do
        post_graphql(query, current_user: group_owner, variables: {
          groupFullPath: group.full_path
        })

        expect_graphql_errors_to_be_empty
      end

      it "#{fixtures_path}#{group_runners_query}.paginated.json" do
        post_graphql(query, current_user: group_owner, variables: {
          groupFullPath: group.full_path,
          first: 1
        })

        expect_graphql_errors_to_be_empty
      end
    end

    describe GraphQL::Query, type: :request do
      group_runners_count_query = 'list/group_runners_count.query.graphql'

      let_it_be(:query) do
        get_graphql_query_as_string("#{query_path}#{group_runners_count_query}")
      end

      it "#{fixtures_path}#{group_runners_count_query}.json" do
        post_graphql(query, current_user: group_owner, variables: {
          groupFullPath: group.full_path
        })

        expect_graphql_errors_to_be_empty
      end
    end
  end
end
