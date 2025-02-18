# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Namespaces (JavaScript fixtures)', feature_category: :groups_and_projects do
  include ApiHelpers
  include JavaScriptFixturesHelpers
  include GraphqlHelpers

  runners_token = 'runnerstoken:intabulasreferre'

  let_it_be(:namespace) { create(:namespace, :with_root_storage_statistics, name: 'frontend-fixtures') }

  let_it_be(:project_boilerplate) do
    create(
      :project,
      name: 'Html5 Boilerplate',
      path: 'html5-boilerplate',
      namespace: namespace,
      runners_token: runners_token
    )
  end

  let_it_be(:project_twitter) do
    create(
      :project,
      name: 'Twitter',
      path: 'twitter',
      namespace: namespace,
      runners_token: runners_token
    )
  end

  let_it_be(:user) { project_boilerplate.owner }

  describe 'Storage', feature_category: :consumables_cost_management do
    describe GraphQL::Query, type: :request do
      include GraphqlHelpers
      base_input_path = 'usage_quotas/storage/namespace/queries/'
      base_output_path = 'graphql/usage_quotas/storage/namespace/'

      context 'for namespace storage statistics query' do
        before do
          if Gitlab.ee?
            namespace.update!(
              additional_purchased_storage_size: 10_240
            )
          end

          namespace.root_storage_statistics.update!(
            storage_size: 4.gigabytes,
            container_registry_size: 1200.megabytes,
            registry_size_estimated: false,
            dependency_proxy_size: 1300.megabytes,
            repository_size: 100.megabytes,
            lfs_objects_size: 100.megabytes,
            wiki_size: 100.megabytes,
            build_artifacts_size: 100.megabytes,
            packages_size: 100.megabytes,
            snippets_size: 100.megabytes,
            pipeline_artifacts_size: 100.megabytes,
            uploads_size: 100.megabytes,
            notification_level: "warning"
          )
        end

        query_name = 'namespace_storage.query.graphql'

        it "#{base_output_path}#{query_name}.json" do
          query = get_graphql_query_as_string("#{base_input_path}#{query_name}", ee: Gitlab.ee?)

          post_graphql(
            query,
            current_user: user,
            variables: {
              fullPath: namespace.full_path
            }
          )

          expect_graphql_errors_to_be_empty
        end
      end

      context 'for project storage statistics query' do
        before do
          project_twitter.update!(
            repository_size_limit: 100_000
          )
          project_twitter.statistics.update!(
            repository_size: 209_710,
            lfs_objects_size: 209_720,
            build_artifacts_size: 1_272_375,
            pipeline_artifacts_size: 0,
            wiki_size: 0,
            packages_size: 0
          )

          project_boilerplate.update!(
            repository_size_limit: 100_000
          )
          project_boilerplate.statistics.update!(
            repository_size: 0,
            lfs_objects_size: 0,
            build_artifacts_size: 1_272_375,
            pipeline_artifacts_size: 0,
            wiki_size: 0,
            packages_size: 0
          )
        end

        query_name = 'project_list_storage.query.graphql'

        it "#{base_output_path}#{query_name}.json" do
          query = get_graphql_query_as_string("#{base_input_path}#{query_name}", ee: Gitlab.ee?)

          post_graphql(
            query,
            current_user: user,
            variables: {
              fullPath: namespace.full_path,
              first: 10
            }
          )

          expect_graphql_errors_to_be_empty
        end
      end
    end
  end

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
