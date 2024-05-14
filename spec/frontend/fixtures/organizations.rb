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

    let_it_be(:current_user) { create(:user) }
    let_it_be(:organizations) { create_list(:organization, 3) }
    let_it_be(:organization_users) do
      organizations.map do |organization|
        create(:organization_user, organization: organization, user: current_user)
      end
    end

    let_it_be(:organization_details) do
      organizations.map do |organization|
        create(:organization_detail, organization: organization)
      end
    end

    before do
      sign_in(current_user)
    end

    describe 'organizations' do
      base_input_path = 'organizations/shared/graphql/queries/'
      base_output_path = 'graphql/organizations/'
      query_name = 'organizations.query.graphql'

      it "#{base_output_path}#{query_name}.json" do
        query = get_graphql_query_as_string("#{base_input_path}#{query_name}")

        post_graphql(query, current_user: current_user, variables: { search: '', first: 3 })

        expect_graphql_errors_to_be_empty
      end
    end
  end
end
