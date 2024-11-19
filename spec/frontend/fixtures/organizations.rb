# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::GroupsController, '(JavaScript fixtures)', type: :controller, feature_category: :cell do
  include JavaScriptFixturesHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:organization) { create(:organization) }
  let_it_be(:organization_user) { create(:organization_user, organization: organization, user: current_user) }

  before do
    sign_in(current_user)
  end

  it 'controller/organizations/groups/post.json' do
    post :create, params: {
      organization_path: organization.path,
      group: {
        name: 'Foo bar',
        path: 'foo-bar',
        visibility_level: Gitlab::VisibilityLevel::INTERNAL
      }
    }, format: :json

    expect(response).to be_successful
  end
end

RSpec.describe 'Organizations (GraphQL fixtures)', feature_category: :cell do
  describe GraphQL::Query, type: :request do
    include GraphqlHelpers
    include JavaScriptFixturesHelpers

    let_it_be_with_reload(:current_user) { create(:user) }
    let_it_be(:user) { create(:user) }
    let_it_be(:organizations) { create_list(:organization, 3) }
    let_it_be(:organization) { organizations.first }
    let_it_be(:groups) { create_list(:group, 3, organization: organization) }
    let_it_be(:group) { groups.first }
    let_it_be(:projects) do
      groups.map do |group|
        create(:project, :public, namespace: group, organization: organization)
      end
    end

    let_it_be(:organization_user_1) { create(:organization_user, organization: organization, user: current_user) }
    let_it_be(:organization_user_2) { create(:organization_owner, organization: organizations[1], user: current_user) }
    let_it_be(:organization_user_3) { create(:organization_user, organization: organizations[2], user: current_user) }
    let_it_be(:organization_user_4) { create(:organization_user, organization: organizations[1], user: user) }

    let_it_be(:organization_details) do
      organizations.map do |organization|
        create(:organization_detail, organization: organization)
      end
    end

    before_all do
      group.add_owner(current_user)
    end

    before do
      sign_in(current_user)
    end

    describe 'current user organizations' do
      base_input_path = 'organizations/shared/graphql/queries/'
      base_output_path = 'graphql/organizations/'
      query_name = 'current_user_organizations.query.graphql'

      it "#{base_output_path}#{query_name}.json" do
        query = get_graphql_query_as_string("#{base_input_path}#{query_name}")

        post_graphql(query, current_user: current_user, variables: { search: '', first: 3 })

        expect_graphql_errors_to_be_empty
      end
    end

    describe 'instance organizations' do
      base_input_path = 'organizations/shared/graphql/queries/'
      base_output_path = 'graphql/organizations/'
      query_name = 'organizations.query.graphql'

      it "#{base_output_path}#{query_name}.json" do
        query = get_graphql_query_as_string("#{base_input_path}#{query_name}")

        post_graphql(query, current_user: current_user, variables: { search: '', first: 3 })

        expect_graphql_errors_to_be_empty
      end
    end

    describe 'organization groups' do
      base_input_path = 'organizations/shared/graphql/queries/'
      base_output_path = 'graphql/organizations/'
      query_name = 'groups.query.graphql'

      it "#{base_output_path}#{query_name}.json" do
        query = get_graphql_query_as_string("#{base_input_path}#{query_name}")

        post_graphql(
          query,
          current_user: current_user,
          variables: { id: organization.to_global_id, search: '', first: 3, sort: 'created_at_asc' }
        )

        expect_graphql_errors_to_be_empty
      end
    end

    describe 'organization update group' do
      base_input_path = 'organizations/groups/edit/graphql/mutations/'
      base_output_path = 'graphql/organizations/'
      mutation_name = 'group_update.mutation.graphql'

      it "#{base_output_path}#{mutation_name}.json" do
        mutation = get_graphql_query_as_string("#{base_input_path}#{mutation_name}")

        post_graphql(
          mutation,
          current_user: current_user,
          variables: {
            input: {
              full_path: group.full_path,
              name: "#{group.name} updated",
              path: "#{group.path}-updated"
            }
          }
        )

        expect_graphql_errors_to_be_empty
      end

      it "#{base_output_path}#{mutation_name}_with_errors.json" do
        mutation = get_graphql_query_as_string("#{base_input_path}#{mutation_name}")

        post_graphql(
          mutation,
          current_user: current_user,
          variables: {
            input: {
              full_path: group.full_path,
              name: "#{group.name} updated",
              path: "#{group.path}-updated",
              visibility: 'private'
            }
          }
        )

        expect_graphql_errors_to_be_empty
      end
    end

    describe 'organization projects' do
      base_input_path = 'organizations/shared/graphql/queries/'
      base_output_path = 'graphql/organizations/'
      query_name = 'projects.query.graphql'

      it "#{base_output_path}#{query_name}.json" do
        query = get_graphql_query_as_string("#{base_input_path}#{query_name}")

        post_graphql(
          query,
          current_user: current_user,
          variables: { id: organization.to_global_id, search: '', first: 3, sort: 'created_at_asc' }
        )

        expect_graphql_errors_to_be_empty
      end
    end

    describe 'organization users' do
      base_input_path = 'organizations/users/graphql/queries/'
      base_output_path = 'graphql/organizations/'
      query_name = 'organization_users.query.graphql'

      let_it_be(:organization_user_4) { create(:organization_user, organization: organization) }
      let_it_be(:admin) { create(:user, :admin) }
      let_it_be(:organization_user_5) { create(:organization_user, organization: organization, user: admin) }

      it "#{base_output_path}#{query_name}.json" do
        query = get_graphql_query_as_string("#{base_input_path}#{query_name}")

        post_graphql(
          query,
          current_user: current_user,
          variables: { id: organizations[1].to_global_id, before: '', after: '' }
        )

        expect_graphql_errors_to_be_empty
      end
    end

    describe 'organization create' do
      base_input_path = 'organizations/new/graphql/mutations/'
      base_output_path = 'graphql/organizations/'
      mutation_name = 'organization_create.mutation.graphql'

      it "#{base_output_path}#{mutation_name}.json" do
        mutation = get_graphql_query_as_string("#{base_input_path}#{mutation_name}")

        post_graphql(
          mutation,
          current_user: current_user,
          variables: {
            input: {
              name: 'Foo bar',
              path: 'foo-bar',
              description: 'foo bar description',
              avatar: nil
            }
          }
        )

        expect_graphql_errors_to_be_empty
      end

      it "#{base_output_path}#{mutation_name}_with_errors.json" do
        mutation = get_graphql_query_as_string("#{base_input_path}#{mutation_name}")

        post_graphql(
          mutation,
          current_user: current_user,
          variables: {
            input: {
              name: 'Foo bar',
              path: 'f',
              description: 'foo bar description',
              avatar: nil
            }
          }
        )

        expect_graphql_errors_to_be_empty
      end
    end

    describe 'organization update' do
      base_input_path = 'organizations/settings/general/graphql/mutations/'
      base_output_path = 'graphql/organizations/'
      mutation_name = 'organization_update.mutation.graphql'

      it "#{base_output_path}#{mutation_name}.json" do
        mutation = get_graphql_query_as_string("#{base_input_path}#{mutation_name}")

        post_graphql(
          mutation,
          current_user: current_user,
          variables: {
            input: {
              id: organizations[1].to_global_id,
              name: 'Foo bar',
              description: 'foo bar description',
              avatar: nil
            }
          }
        )

        expect_graphql_errors_to_be_empty
      end

      it "#{base_output_path}#{mutation_name}_with_errors.json" do
        mutation = get_graphql_query_as_string("#{base_input_path}#{mutation_name}")

        post_graphql(
          mutation,
          current_user: current_user,
          variables: {
            input: {
              id: organizations[1].to_global_id,
              path: 'f',
              avatar: nil
            }
          }
        )

        expect_graphql_errors_to_be_empty
      end
    end

    describe 'organization user update' do
      base_input_path = 'organizations/users/graphql/mutations/'
      base_output_path = 'graphql/organizations/'
      mutation_name = 'organization_user_update.mutation.graphql'

      it "#{base_output_path}#{mutation_name}.json" do
        mutation = get_graphql_query_as_string("#{base_input_path}#{mutation_name}")

        post_graphql(
          mutation,
          current_user: current_user,
          variables: {
            input: {
              id: organization_user_4.to_global_id,
              access_level: :OWNER
            }
          }
        )

        expect_graphql_errors_to_be_empty
      end

      it "#{base_output_path}#{mutation_name}_with_errors.json" do
        mutation = get_graphql_query_as_string("#{base_input_path}#{mutation_name}")

        post_graphql(
          mutation,
          current_user: current_user,
          variables: {
            input: {
              id: organization_user_2.to_global_id,
              access_level: :DEFAULT
            }
          }
        )

        expect_graphql_errors_to_be_empty
      end
    end
  end
end
