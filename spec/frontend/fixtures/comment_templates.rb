# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GraphQL::Query, type: :request, feature_category: :user_profile do
  include JavaScriptFixturesHelpers
  include ApiHelpers
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  before do
    sign_in(current_user)
  end

  context 'when user has no comment templates' do
    base_input_path = 'pages/profiles/comment_templates/queries/'
    base_output_path = 'graphql/comment_templates/'
    query_name = 'saved_replies.query.graphql'

    it "#{base_output_path}saved_replies_empty.query.graphql.json" do
      query = get_graphql_query_as_string("#{base_input_path}#{query_name}")

      post_graphql(query, current_user: current_user)

      expect_graphql_errors_to_be_empty
    end
  end

  context 'when user has comment templates' do
    base_input_path = 'pages/profiles/comment_templates/queries/'
    base_output_path = 'graphql/comment_templates/'
    query_name = 'saved_replies.query.graphql'

    it "#{base_output_path}saved_replies.query.graphql.json" do
      create(:saved_reply, user: current_user)
      create(:saved_reply, user: current_user)

      query = get_graphql_query_as_string("#{base_input_path}#{query_name}")

      post_graphql(query, current_user: current_user)

      expect_graphql_errors_to_be_empty
    end
  end

  context 'when user creates comment template' do
    base_input_path = 'pages/profiles/comment_templates/queries/'
    base_output_path = 'graphql/comment_templates/'
    query_name = 'create_saved_reply.mutation.graphql'

    it "#{base_output_path}#{query_name}.json" do
      query = get_graphql_query_as_string("#{base_input_path}#{query_name}")

      post_graphql(query, current_user: current_user, variables: { name: "Test", content: "Test content" })

      expect_graphql_errors_to_be_empty
    end
  end

  context 'when user creates comment template and it errors' do
    base_input_path = 'pages/profiles/comment_templates/queries/'
    base_output_path = 'graphql/comment_templates/'
    query_name = 'create_saved_reply.mutation.graphql'

    it "#{base_output_path}create_saved_reply_with_errors.mutation.graphql.json" do
      query = get_graphql_query_as_string("#{base_input_path}#{query_name}")

      post_graphql(query, current_user: current_user, variables: { name: nil, content: nil })

      expect(flattened_errors).not_to be_empty
    end
  end
end
