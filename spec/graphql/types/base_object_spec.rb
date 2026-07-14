# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::BaseObject, feature_category: :api do
  include GraphqlHelpers

  describe 'scoping items' do
    include_context 'with test GraphQL schema'

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
        scope_validator: scope_validator,
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
        scope_validator: scope_validator,
        x: {
          ys: (95..105).to_a.map { |id| { id: id } }
        }
      }

      doc = ->(after) do
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

      data = {
        scope_validator: scope_validator,
        user_ids: [inactive, *active_users].map(&:id)
      }

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
        scope_validator: scope_validator,
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
        scope_validator: scope_validator,
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
        scope_validator: scope_validator,
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

      data = {
        scope_validator: scope_validator,
        user_ids: [*inactive, *active_users].map(&:id)
      }

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

    describe '.authorize' do
      let_it_be(:read_only_type) do
        Class.new(described_class) do
          authorize :read_only
        end
      end

      let_it_be(:inherited_read_only_type) { Class.new(read_only_type) }

      it 'keeps track of the specified value' do
        expect(described_class.authorize).to be_nil
        expect(read_only_type.authorize).to match_array [:read_only]
        expect(inherited_read_only_type.authorize).to match_array [:read_only]
      end

      it 'can not redefine the authorize value' do
        expect { read_only_type.authorize(:write_only) }.to raise_error('Cannot redefine authorize')
      end
    end
  end

  describe '#authorized?', feature_category: :permissions do
    let_it_be(:project) { create(:project) }
    let_it_be(:current_user) { create(:user, developer_of: project) }

    let_it_be(:granular_token) do
      create(:granular_pat, user: current_user, boundary: ::Authz::Boundary.for(project), permissions: [:read_wiki])
    end

    let_it_be(:insufficient_granular_token) do
      create(:granular_pat, user: current_user, boundary: ::Authz::Boundary.for(project),
        permissions: [:create_work_item])
    end

    let_it_be(:legacy_token) { create(:personal_access_token, user: current_user) }

    let(:object) { project }

    subject(:authorized) { type.authorized?(object, context) }

    context 'with an `authorize` directive' do
      let(:scope_validator) { instance_double(::Gitlab::Auth::ScopeValidator, valid_for?: true) }
      let(:context) { { current_user: current_user, scope_validator: scope_validator } }

      let_it_be(:type) do
        Class.new(described_class) { authorize :read_resource }
      end

      before do
        allow(Ability).to receive(:allowed?).with(current_user, :read_resource, object).and_return(true)
      end

      context 'when the user has the ability and the token scope is sufficient' do
        it 'is authorized' do
          is_expected.to be(true)
        end
      end

      context 'when the user lacks the ability' do
        before do
          allow(Ability).to receive(:allowed?).with(current_user, :read_resource, object).and_return(false)
        end

        it 'is not authorized' do
          is_expected.to be(false)
        end
      end

      context 'when the token scope is insufficient' do
        before do
          allow(scope_validator).to receive(:valid_for?).and_return(false)
        end

        it 'is not authorized, before any ability is checked' do
          is_expected.to be(false)
        end
      end

      context 'when the ability is named in skip_type_authorization' do
        before do
          context[:skip_type_authorization] = :read_resource
        end

        it 'skips the ability check' do
          is_expected.to be(true)
        end
      end
    end

    context 'with an `authorize_granular_token` directive' do
      let_it_be(:type) do
        Class.new(described_class) do
          authorize_granular_token(permissions: :read_wiki, boundary: :itself, boundary_type: :project)
        end
      end

      let(:context) { { current_user: current_user, access_token: access_token } }

      context 'with a granular token' do
        context 'when the token authorizes the boundary' do
          let(:access_token) { granular_token }

          it 'grants access' do
            is_expected.to be(true)
          end
        end

        context 'when the token does not authorize the boundary' do
          let(:access_token) { insufficient_granular_token }

          it 'denies access' do
            is_expected.to be(false)
          end
        end

        context 'when the `granular_personal_access_tokens` feature flag is disabled' do
          let(:access_token) { granular_token }

          before do
            stub_feature_flags(granular_personal_access_tokens: false)
          end

          it 'denies access' do
            is_expected.to be(false)
          end
        end
      end

      context 'with a legacy token' do
        let(:access_token) { legacy_token }

        it 'grants access' do
          is_expected.to be(true)
        end
      end
    end

    context 'without an `authorize_granular_token` directive' do
      let_it_be(:type) { Class.new(described_class) }

      let(:context) { { current_user: current_user, access_token: access_token } }

      context 'with a granular token' do
        let(:access_token) { granular_token }

        it 'denies access' do
          is_expected.to be(false)
        end
      end
    end
  end
end
