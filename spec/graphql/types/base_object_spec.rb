# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::BaseObject do
  include GraphqlHelpers

  describe 'scoping items' do
    let_it_be(:custom_auth) do
      Class.new(::Gitlab::Graphql::Authorize::ObjectAuthorization) do
        def any?
          true
        end

        def ok?(object, _current_user)
          return false if object == { id: 100 }
          return false if object.try(:deactivated?)

          true
        end
      end
    end

    let_it_be(:test_schema) do
      auth = custom_auth.new(nil)

      base_object = Class.new(described_class) do
        # Override authorization so we don't need to mock Ability
        define_singleton_method :authorization do
          auth
        end
      end

      y_type = Class.new(base_object) do
        graphql_name 'Y'
        authorize :read_y
        field :id, Integer, null: false

        def id
          object[:id]
        end
      end

      number_type = Module.new do
        include ::Types::BaseInterface

        graphql_name 'Number'

        field :value, Integer, null: false
      end

      odd_type = Class.new(described_class) do
        graphql_name 'Odd'
        implements number_type

        authorize :read_odd
        field :odd_value, Integer, null: false

        def odd_value
          object[:value]
        end
      end

      even_type = Class.new(described_class) do
        graphql_name 'Even'
        implements number_type

        authorize :read_even
        field :even_value, Integer, null: false

        def even_value
          object[:value]
        end
      end

      # an abstract type, delegating authorization to members
      odd_or_even = Class.new(::Types::BaseUnion) do
        graphql_name 'OddOrEven'

        possible_types odd_type, even_type

        define_singleton_method :resolve_type do |object, ctx|
          if object[:value].odd?
            odd_type
          else
            even_type
          end
        end
      end

      number_type.define_singleton_method :resolve_type do |object, ctx|
        odd_or_even.resolve_type(object, ctx)
      end

      x_type = Class.new(base_object) do
        graphql_name 'X'
        # Scalar types
        field :title, String, null: true
        # monomorphic types
        field :lazy_list_of_ys, [y_type], null: true
        field :list_of_lazy_ys, [y_type], null: true
        field :array_ys_conn, y_type.connection_type, null: true
        # polymorphic types
        field :polymorphic_conn, odd_or_even.connection_type, null: true
        field :polymorphic_object, odd_or_even, null: true do
          argument :value, Integer, required: true
        end
        field :interface_conn, number_type.connection_type, null: true

        def lazy_list_of_ys
          ::Gitlab::Graphql::Lazy.new { object[:ys] }
        end

        def list_of_lazy_ys
          object[:ys].map { |y| ::Gitlab::Graphql::Lazy.new { y } }
        end

        def array_ys_conn
          object[:ys].dup
        end

        def polymorphic_conn
          object[:values].dup
        end
        alias_method :interface_conn, :polymorphic_conn

        def polymorphic_object(value)
          value
        end
      end

      user_type = Class.new(base_object) do
        graphql_name 'User'
        authorize :read_user
        field 'name', String, null: true
      end

      Class.new(GraphQL::Schema) do
        lazy_resolve ::Gitlab::Graphql::Lazy, :force
        use ::GraphQL::Pagination::Connections
        use ::Gitlab::Graphql::Pagination::Connections

        query(Class.new(::Types::BaseObject) do
          graphql_name 'Query'
          field :x, x_type, null: true
          field :users, user_type.connection_type, null: true

          def x
            ::Gitlab::Graphql::Lazy.new { context[:x] }
          end

          def users
            ::Gitlab::Graphql::Lazy.new { User.id_in(context[:user_ids]).order(id: :asc) }
          end
        end)

        def unauthorized_object(err)
          nil
        end
      end
    end

    def document(path)
      GraphQL.parse(<<~GQL)
      query {
        x {
          title
          #{query_graphql_path(path, 'id')}
        }
      }
      GQL
    end

    let(:data) do
      {
        x: {
          title: 'Hey',
          ys: [{ id: 1 }, { id: 100 }, { id: 2 }]
        }
      }
    end

    shared_examples 'array member redaction' do |path|
      let(:result) do
        query = GraphQL::Query.new(test_schema, document: document(path), context: data)
        query.result.to_h
      end

      it 'redacts the unauthorized array member' do
        expect(graphql_dig_at(result, 'data', 'x', 'title')).to eq('Hey')
        expect(graphql_dig_at(result, 'data', 'x', *path)).to contain_exactly(
          eq({ 'id' => 1 }),
          eq({ 'id' => 2 })
        )
      end
    end

    # For example a batchloaded association
    describe 'a lazy list' do
      it_behaves_like 'array member redaction', %w[lazyListOfYs]
    end

    # For example using a batchloader to map over a set of IDs
    describe 'a list of lazy items' do
      it_behaves_like 'array member redaction', %w[listOfLazyYs]
    end

    describe 'an array connection of items' do
      it_behaves_like 'array member redaction', %w[arrayYsConn nodes]
    end

    describe 'an array connection of items, selecting edges' do
      it_behaves_like 'array member redaction', %w[arrayYsConn edges node]
    end

    it 'paginates arrays correctly' do
      n = 7

      data = {
        x: {
          ys: (95..105).to_a.map { |id| { id: id } }
        }
      }

      doc = lambda do |after|
        GraphQL.parse(<<~GQL)
        query {
          x {
            ys: arrayYsConn(#{attributes_to_graphql(first: n, after: after)}) {
              pageInfo {
                hasNextPage
                hasPreviousPage
                endCursor
              }
              nodes { id }
            }
          }
        }
        GQL
      end
      returned_items = ->(ids) { ids.to_a.map { |id| eq({ 'id' => id }) } }

      query = GraphQL::Query.new(test_schema, document: doc[nil], context: data)
      result = query.result.to_h

      ys = result.dig('data', 'x', 'ys', 'nodes')
      page = result.dig('data', 'x', 'ys', 'pageInfo')
      # We expect this page to be smaller, since we paginate before redaction
      expect(ys).to match_array(returned_items[(95..101).to_a - [100]])
      expect(page).to include('hasNextPage' => true, 'hasPreviousPage' => false)

      cursor = page['endCursor']
      query_2 = GraphQL::Query.new(test_schema, document: doc[cursor], context: data)
      result_2 = query_2.result.to_h

      ys = result_2.dig('data', 'x', 'ys', 'nodes')
      page = result_2.dig('data', 'x', 'ys', 'pageInfo')
      expect(ys).to match_array(returned_items[102..105])
      expect(page).to include('hasNextPage' => false, 'hasPreviousPage' => true)
    end

    it 'filters connections correctly' do
      active_users = create_list(:user, 3, state: :active)
      inactive = create(:user, state: :deactivated)

      data = { user_ids: [inactive, *active_users].map(&:id) }

      doc = GraphQL.parse(<<~GQL)
      query {
        users { nodes { name } }
      }
      GQL

      query = GraphQL::Query.new(test_schema, document: doc, context: data)
      result = query.result.to_h

      expect(result.dig('data', 'users', 'nodes')).to match_array(active_users.map do |u|
        eq({ 'name' => u.name })
      end)
    end

    it 'filters polymorphic connections' do
      data = {
        current_user: :the_user,
        x: {
          values: [{ value: 1 }, { value: 2 }, { value: 3 }, { value: 4 }]
        }
      }

      doc = GraphQL.parse(<<~GQL)
        query {
          x {
            things: polymorphicConn {
              nodes {
                ... on Odd { oddValue }
                ... on Even { evenValue }
              }
            }
          }
        }
      GQL

      # Each ability check happens twice: once in the collection, and once
      # on the type. We expect the ability checks to be cached.
      expect(Ability).to receive(:allowed?).twice
        .with(:the_user, :read_odd, { value: 1 }).and_return(true)
      expect(Ability).to receive(:allowed?).once
        .with(:the_user, :read_odd, { value: 3 }).and_return(false)
      expect(Ability).to receive(:allowed?).once
        .with(:the_user, :read_even, { value: 2 }).and_return(false)
      expect(Ability).to receive(:allowed?).twice
        .with(:the_user, :read_even, { value: 4 }).and_return(true)

      query = GraphQL::Query.new(test_schema, document: doc, context: data)
      result = query.result.to_h

      things = result.dig('data', 'x', 'things', 'nodes')

      expect(things).to contain_exactly(
        { 'oddValue' => 1 },
        { 'evenValue' => 4 }
      )
    end

    it 'filters interface connections' do
      data = {
        current_user: :the_user,
        x: {
          values: [{ value: 1 }, { value: 2 }, { value: 3 }, { value: 4 }]
        }
      }

      doc = GraphQL.parse(<<~GQL)
        query {
          x {
            things: interfaceConn {
              nodes {
                value
                ... on Odd { oddValue }
                ... on Even { evenValue }
              }
            }
          }
        }
      GQL

      # Each ability check happens twice: once in the collection, and once
      # on the type. We expect the ability checks to be cached.
      expect(Ability).to receive(:allowed?).twice
        .with(:the_user, :read_odd, { value: 1 }).and_return(true)
      expect(Ability).to receive(:allowed?).once
        .with(:the_user, :read_odd, { value: 3 }).and_return(false)
      expect(Ability).to receive(:allowed?).once
        .with(:the_user, :read_even, { value: 2 }).and_return(false)
      expect(Ability).to receive(:allowed?).twice
        .with(:the_user, :read_even, { value: 4 }).and_return(true)

      query = GraphQL::Query.new(test_schema, document: doc, context: data)
      result = query.result.to_h

      things = result.dig('data', 'x', 'things', 'nodes')

      expect(things).to contain_exactly(
        { 'value' => 1, 'oddValue' => 1 },
        { 'value' => 4, 'evenValue' => 4 }
      )
    end

    it 'redacts polymorphic objects' do
      data = {
        current_user: :the_user,
        x: {
          values: [{ value: 1 }]
        }
      }

      doc = GraphQL.parse(<<~GQL)
        query {
          x {
            ok: polymorphicObject(value: 1) {
              ... on Odd { oddValue }
              ... on Even { evenValue }
            }
            bad: polymorphicObject(value: 3) {
              ... on Odd { oddValue }
              ... on Even { evenValue }
            }
          }
        }
      GQL

      # Each ability check happens twice: once in the collection, and once
      # on the type. We expect the ability checks to be cached.
      expect(Ability).to receive(:allowed?).once
        .with(:the_user, :read_odd, { value: 1 }).and_return(true)
      expect(Ability).to receive(:allowed?).once
        .with(:the_user, :read_odd, { value: 3 }).and_return(false)

      query = GraphQL::Query.new(test_schema, document: doc, context: data)
      result = query.result.to_h

      expect(result.dig('data', 'x', 'ok')).to eq({ 'oddValue' => 1 })
      expect(result.dig('data', 'x', 'bad')).to be_nil
    end

    it 'paginates before scoping' do
      # Inactive first so they sort first
      n = 3
      inactive = create_list(:user, n - 1, state: :deactivated)
      active_users = create_list(:user, 2, state: :active)

      data = { user_ids: [*inactive, *active_users].map(&:id) }

      doc = GraphQL.parse(<<~GQL)
      query {
        users(first: #{n}) {
          pageInfo { hasNextPage }
          nodes { name } }
      }
      GQL

      query = GraphQL::Query.new(test_schema, document: doc, context: data)
      result = query.result.to_h

      # We expect the page to be loaded and then filtered - i.e. to have all
      # deactivated users removed.
      expect(result.dig('data', 'users', 'pageInfo', 'hasNextPage')).to be_truthy
      expect(result.dig('data', 'users', 'nodes'))
        .to contain_exactly({ 'name' => active_users.first.name })
    end
  end
end
