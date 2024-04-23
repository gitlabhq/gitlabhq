# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Work items", '(JavaScript fixtures)', type: :request, feature_category: :portfolio_management do
  include ApiHelpers
  include GraphqlHelpers
  include JavaScriptFixturesHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }

  let(:group_work_item_types_query_path) { 'work_items/graphql/group_work_item_types.query.graphql' }
  let(:project_work_item_types_query_path) { 'work_items/graphql/project_work_item_types.query.graphql' }

  it 'graphql/work_items/group_work_item_types.query.graphql.json' do
    query = get_graphql_query_as_string(group_work_item_types_query_path)

    post_graphql(query, current_user: user, variables: { fullPath: group.full_path })

    expect_graphql_errors_to_be_empty
  end

  it 'graphql/work_items/project_work_item_types.query.graphql.json' do
    query = get_graphql_query_as_string(project_work_item_types_query_path)

    post_graphql(query, current_user: user, variables: { fullPath: project.full_path })

    expect_graphql_errors_to_be_empty
  end
end
