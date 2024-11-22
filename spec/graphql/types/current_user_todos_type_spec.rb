# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CurrentUserTodos'] do
  include GraphqlHelpers

  specify { expect(described_class.graphql_name).to eq('CurrentUserTodos') }

  specify { expect(described_class).to have_graphql_fields(:current_user_todos).only }

  # Request store is necessary to prevent duplicate max-member-access lookups
  describe '.current_user_todos', :request_store, :aggregate_failures do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:issue_a) { create(:issue, project: project) }
    let_it_be(:issue_b) { create(:issue, project: project) }

    let_it_be(:todo_a) { create(:todo, :pending, user: user, project: project, target: issue_a) }
    let_it_be(:todo_b) { create(:todo, :done,    user: user, project: project, target: issue_a) }
    let_it_be(:todo_c) { create(:todo, :pending, user: user, project: project, target: issue_b) }
    let_it_be(:todo_d) { create(:todo, :done,    user: user, project: project, target: issue_b) }

    let_it_be(:merge_request) { create(:merge_request, source_project: project) }
    let_it_be(:todo_e) { create(:todo, :pending, user: user, project: project, target: merge_request) }

    let(:object_type) do
      fresh_object_type('HasTodos').tap { _1.implements(Types::CurrentUserTodos) }
    end

    let(:id_enum) do
      Class.new(Types::BaseEnum) do
        graphql_name 'AorB'

        value 'A'
        value 'B'
      end
    end

    let(:query_type) do
      i_a = issue_a
      i_b = issue_b
      issue_id = id_enum
      mr = merge_request

      q = fresh_object_type('Query')

      q.field :issue, null: false, type: object_type do
        argument :id, type: issue_id, required: true
      end

      q.field :mr, null: false, type: object_type

      q.define_method(:issue) do |id:|
        case id
        when 'A'
          i_a
        when 'B'
          i_b
        end
      end

      q.define_method(:mr) { mr }

      q
    end

    let(:todo_fragment) do
      <<-GQL
      fragment todos on HasTodos {
        todos: currentUserTodos {
          nodes { id }
        }
      }
      GQL
    end

    let(:base_query) do
      <<-GQL
      query {
        issue(id: A) { ... todos }
      }
      #{todo_fragment}
      GQL
    end

    let(:query_without_state_arguments) do
      <<-GQL
      query {
        a: issue(id: A) {
          ... todos
        }
        b: issue(id: B) {
          ... todos
        }
        c: mr {
          ... todos
        }
        d: mr {
          ... todos
        }
        e: issue(id: A) {
          ... todos
        }
      }

      #{todo_fragment}
      GQL
    end

    let(:with_state_arguments) do
      <<-GQL
      query {
        a: issue(id: A) {
          todos: currentUserTodos(state: pending) { nodes { id } }
        }
        b: issue(id: B) {
          todos: currentUserTodos(state: done) { nodes { id } }
        }
        c: mr {
          ... todos
        }
      }

      #{todo_fragment}
      GQL
    end

    before_all do
      project.add_developer(user)
    end

    it 'batches todo lookups, linear in the number of target types/state arguments' do
      # The baseline is 4 queries:
      #
      # When we batch queries, we see the following three groups of queries:
      # # user authorization
      # 1. SELECT "users".* FROM "users"
      #     INNER JOIN "project_authorizations"
      #     ON "users"."id" = "project_authorizations"."user_id"
      #     WHERE "project_authorizations"."project_id" = project_id
      #     AND "project_authorizations"."access_level" = 50
      # 2. SELECT MAX("project_authorizations"."access_level") AS maximum_access_level,
      #           "project_authorizations"."user_id" AS project_authorizations_user_id
      #    FROM "project_authorizations"
      #    WHERE "project_authorizations"."project_id" = project_id
      #    AND "project_authorizations"."user_id" = user_id
      #    GROUP BY "project_authorizations"."user_id"
      #
      # # find todos for issues
      # 1. SELECT "todos".* FROM "todos"
      #    WHERE "todos"."user_id" = user_id
      #    AND ("todos"."state" IN ('done','pending'))
      #    AND "todos"."target_id" IN (issue_a, issue_b)
      #    AND "todos"."target_type" = 'Issue' ORDER BY "todos"."id" DESC
      #
      # # find todos for merge_requests
      # 1. SELECT "todos".* FROM "todos" WHERE "todos"."user_id" = user_id
      #    AND ("todos"."state" IN ('done','pending'))
      #    AND "todos"."target_id" = merge_request
      #    AND "todos"."target_type" = 'MergeRequest' ORDER BY "todos"."id" DESC
      control = ActiveRecord::QueryRecorder.new do
        execute_query(query_type, graphql: base_query)
      end

      expect do
        execute_query(query_type, graphql: query_without_state_arguments)
      end.not_to exceed_query_limit(control).with_threshold(1) # at present this is 4

      expect do
        execute_query(query_type, graphql: with_state_arguments)
      end.not_to exceed_query_limit(control).with_threshold(2)
    end

    it 'returns correct data' do
      result = execute_query(query_type, graphql: query_without_state_arguments, raise_on_error: true).to_h

      expect(result.dig('data', 'a', 'todos', 'nodes')).to contain_exactly(
        a_graphql_entity_for(todo_a),
        a_graphql_entity_for(todo_b)
      )
      expect(result.dig('data', 'b', 'todos', 'nodes')).to contain_exactly(
        a_graphql_entity_for(todo_c),
        a_graphql_entity_for(todo_d)
      )
      expect(result.dig('data', 'c', 'todos', 'nodes')).to contain_exactly(
        a_graphql_entity_for(todo_e)
      )
      expect(result.dig('data', 'd', 'todos', 'nodes')).to contain_exactly(
        a_graphql_entity_for(todo_e)
      )
      expect(result.dig('data', 'e', 'todos', 'nodes')).to contain_exactly(
        a_graphql_entity_for(todo_a),
        a_graphql_entity_for(todo_b)
      )
    end

    it 'returns correct data, when state arguments are supplied' do
      result = execute_query(query_type, raise_on_error: true, graphql: with_state_arguments).to_h

      expect(result.dig('data', 'a', 'todos', 'nodes')).to contain_exactly(
        a_graphql_entity_for(todo_a)
      )
      expect(result.dig('data', 'b', 'todos', 'nodes')).to contain_exactly(
        a_graphql_entity_for(todo_d)
      )
      expect(result.dig('data', 'c', 'todos', 'nodes')).to contain_exactly(
        a_graphql_entity_for(todo_e)
      )
    end
  end
end
