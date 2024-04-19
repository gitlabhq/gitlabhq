# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Runner (JavaScript fixtures)', feature_category: :fleet_visibility do
  include AdminModeHelper
  include ApiHelpers
  include JavaScriptFixturesHelpers
  include GraphqlHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:project_2) { create(:project, :repository, :public) }

  let_it_be(:runner) { create(:ci_runner, :instance, :unregistered, description: 'My Runner', creator: admin) }

  let_it_be(:runner_mach_1) { create(:ci_runner_machine, runner: runner, version: '1.0.0', contacted_at: Time.current) }
  let_it_be(:runner_mach_2) { create(:ci_runner_machine, runner: runner, version: '1.0.0', contacted_at: Time.current) }

  let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group]) }
  let_it_be(:group_runner_2) { create(:ci_runner, :group, groups: [group]) }
  let_it_be(:project_runner) do
    create(:ci_runner, :project, :unregistered, projects: [project, project_2])
  end

  let_it_be(:build) { create(:ci_build, runner: runner) }

  query_path = 'ci/runner/graphql/'
  fixtures_path = 'graphql/ci/runner/'

  after(:all) do
    remove_repository(project)
  end

  before do
    allow_next_instance_of(::Gitlab::Ci::RunnerUpgradeCheck) do |instance|
      allow(instance).to receive(:check_runner_upgrade_suggestion)
        .and_return([nil, :unavailable])
    end
  end

  describe 'as admin', GraphQL::Query do
    before do
      sign_in(admin)
      enable_admin_mode!(admin)
    end

    describe 'all_runners.query.graphql', type: :request do
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

      it "#{fixtures_path}#{all_runners_query}.with_creator.json" do
        # "last: 1" fetches the first runner created, with admin as "creator"
        post_graphql(query, current_user: admin, variables: { last: 1 })

        expect_graphql_errors_to_be_empty
      end
    end

    describe 'all_runners_count.query.graphql', type: :request do
      all_runners_count_query = 'list/all_runners_count.query.graphql'

      let_it_be(:query) do
        get_graphql_query_as_string("#{query_path}#{all_runners_count_query}")
      end

      it "#{fixtures_path}#{all_runners_count_query}.json" do
        post_graphql(query, current_user: admin, variables: {})

        expect_graphql_errors_to_be_empty
      end
    end

    describe 'runner.query.graphql', type: :request do
      runner_query = 'show/runner.query.graphql'

      let_it_be(:query) do
        get_graphql_query_as_string("#{query_path}#{runner_query}")
      end

      it "#{fixtures_path}#{runner_query}.json" do
        post_graphql(query, current_user: admin, variables: {
          id: runner.to_global_id.to_s
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

    describe 'runner_projects.query.graphql', type: :request do
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

    describe 'runner_jobs.query.graphql', type: :request do
      runner_jobs_query = 'show/runner_jobs.query.graphql'

      let_it_be(:query) do
        get_graphql_query_as_string("#{query_path}#{runner_jobs_query}")
      end

      it "#{fixtures_path}#{runner_jobs_query}.json" do
        post_graphql(query, current_user: admin, variables: {
          id: runner.to_global_id.to_s
        })

        expect_graphql_errors_to_be_empty
      end
    end

    describe 'runner_managers.query.graphql', type: :request do
      runner_managers_query = 'show/runner_managers.query.graphql'

      let_it_be(:query) do
        get_graphql_query_as_string("#{query_path}#{runner_managers_query}")
      end

      it "#{fixtures_path}#{runner_managers_query}.json" do
        post_graphql(query, current_user: admin, variables: {
          runner_id: runner.to_global_id.to_s
        })

        expect_graphql_errors_to_be_empty
      end
    end

    describe 'runner_form.query.graphql', type: :request do
      runner_jobs_query = 'edit/runner_form.query.graphql'

      let_it_be(:query) do
        get_graphql_query_as_string("#{query_path}#{runner_jobs_query}")
      end

      it "#{fixtures_path}#{runner_jobs_query}.json" do
        post_graphql(query, current_user: admin, variables: {
          id: runner.to_global_id.to_s
        })

        expect_graphql_errors_to_be_empty
      end
    end

    describe 'runner_for_registration.query.graphql', :freeze_time, type: :request do
      runner_for_registration_query = 'register/runner_for_registration.query.graphql'

      let_it_be(:query) do
        get_graphql_query_as_string("#{query_path}#{runner_for_registration_query}")
      end

      it "#{fixtures_path}#{runner_for_registration_query}.json" do
        post_graphql(query, current_user: admin, variables: {
          id: runner.to_global_id.to_s
        })

        expect_graphql_errors_to_be_empty
      end
    end

    describe 'runner_create.mutation.graphql', type: :request do
      runner_create_mutation = 'new/runner_create.mutation.graphql'

      let_it_be(:query) do
        get_graphql_query_as_string("#{query_path}#{runner_create_mutation}")
      end

      context 'with runnerType set to INSTANCE_TYPE' do
        it "#{fixtures_path}#{runner_create_mutation}.json" do
          post_graphql(query, current_user: admin, variables: {
            input: {
              runnerType: 'INSTANCE_TYPE',
              description: 'My dummy runner'
            }
          })

          expect_graphql_errors_to_be_empty
        end
      end
    end
  end

  describe 'as group owner', GraphQL::Query do
    let_it_be(:group_owner) { create(:user) }

    before do
      group.add_owner(group_owner)
    end

    describe 'group_runners.query.graphql', type: :request do
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

    describe 'group_runners_count.query.graphql', type: :request do
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
