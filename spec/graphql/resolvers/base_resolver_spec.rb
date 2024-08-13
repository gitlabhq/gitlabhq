# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::BaseResolver, feature_category: :api do
  include GraphqlHelpers
  let_it_be(:current_user) { create(:user) }

  let(:resolver) do
    Class.new(described_class) do
      argument :test, ::GraphQL::Types::Int, required: false
      type [::GraphQL::Types::Int], null: true

      def resolve(test: 100)
        process(object)

        [test, test]
      end

      def process(obj); end
    end
  end

  let(:last_resolver) do
    Class.new(described_class) do
      type [::GraphQL::Types::Int], null: true

      def resolve(**args)
        [1, 2]
      end
    end
  end

  describe '.singular_type' do
    subject { resolver.singular_type }

    context 'for a connection of scalars' do
      let(:resolver) do
        Class.new(described_class) do
          type ::GraphQL::Types::Int.connection_type, null: true
        end
      end

      it { is_expected.to eq(::GraphQL::Types::Int) }
    end

    context 'for a connection of objects' do
      let(:object) do
        Class.new(::Types::BaseObject) do
          graphql_name 'Foo'
        end
      end

      let(:resolver) do
        conn = object.connection_type

        Class.new(described_class) do
          type conn, null: true
        end
      end

      it { is_expected.to eq(object) }
    end

    context 'for a list type' do
      let(:resolver) do
        Class.new(described_class) do
          type [::GraphQL::Types::String], null: true
        end
      end

      it { is_expected.to eq(::GraphQL::Types::String) }
    end

    context 'for a scalar type' do
      let(:resolver) do
        Class.new(described_class) do
          type ::GraphQL::Types::Boolean, null: true
        end
      end

      it { is_expected.to eq(::GraphQL::Types::Boolean) }
    end
  end

  describe '.single' do
    it 'returns a subclass from the resolver' do
      expect(resolver.single.superclass).to eq(resolver)
    end

    it 'has the correct (singular) type' do
      expect(resolver.single.type).to eq(::GraphQL::Types::Int)
    end

    it 'returns the same subclass every time' do
      expect(resolver.single.object_id).to eq(resolver.single.object_id)
    end

    it 'returns a resolver that gives the first result from the original resolver' do
      result = resolve(resolver.single, args: { test: 1 })

      expect(result).to eq(1)
    end
  end

  describe '.when_single' do
    let(:resolver) do
      Class.new(described_class) do
        type [::GraphQL::Types::Int], null: true

        when_single do
          argument :foo, ::GraphQL::Types::Int, required: true
        end

        def resolve(foo: 1)
          [foo * foo]
        end
      end
    end

    it 'does not apply the block to the resolver' do
      expect(resolver.arguments).to be_empty

      result = resolve(resolver)

      expect(result).to eq([1])
    end

    it 'applies the block to the single version of the resolver' do
      expect(resolver.single.arguments).to match('foo' => an_instance_of(::Types::BaseArgument))

      result = resolve(resolver.single, args: { foo: 7 })

      expect(result).to eq(49)
    end

    context 'multiple when_single blocks' do
      let(:resolver) do
        Class.new(described_class) do
          type [::GraphQL::Types::Int], null: true

          when_single do
            argument :foo, ::GraphQL::Types::Int, required: true
          end

          when_single do
            argument :bar, ::GraphQL::Types::Int, required: true
          end

          def resolve(foo: 1, bar: 2)
            [foo * bar]
          end
        end
      end

      it 'applies both blocks to the single version of the resolver' do
        expect(resolver.single.arguments).to match('foo' => ::Types::BaseArgument, 'bar' => ::Types::BaseArgument)

        result = resolve(resolver.single, args: { foo: 7, bar: 5 })

        expect(result).to eq(35)
      end
    end

    context 'inheritance' do
      let(:subclass) do
        Class.new(resolver) do
          when_single do
            argument :inc, ::GraphQL::Types::Int, required: true
          end

          def resolve(foo:, inc:)
            super(foo: foo + inc)
          end
        end
      end

      it 'applies both blocks to the single version of the resolver' do
        expect(resolver.single.arguments).to match('foo' => ::Types::BaseArgument)
        expect(subclass.single.arguments).to match('foo' => ::Types::BaseArgument, 'inc' => ::Types::BaseArgument)

        result = resolve(subclass.single, args: { foo: 7, inc: 1 })

        expect(result).to eq(64)
      end
    end
  end

  context 'when the resolver returns early' do
    let(:resolver) do
      Class.new(described_class) do
        type [::GraphQL::Types::String], null: true

        def ready?(**args)
          [false, %w[early return]]
        end

        def resolve(**args)
          raise 'Should not get here'
        end
      end
    end

    it 'runs correctly in our test framework' do
      expect(resolve(resolver)).to contain_exactly('early', 'return')
    end

    it 'single selects the first early return value' do
      expect(resolve(resolver.single)).to eq('early')
    end

    it 'last selects the last early return value' do
      expect(resolve(resolver.last)).to eq('return')
    end
  end

  describe '.last' do
    it 'returns a subclass from the resolver' do
      expect(last_resolver.last.ancestors).to include(last_resolver)
    end

    it 'returns the same subclass every time' do
      expect(last_resolver.last.object_id).to eq(last_resolver.last.object_id)
    end

    it 'returns a resolver that gives the last result from the original resolver' do
      result = resolve(last_resolver.last)

      expect(result).to eq(2)
    end
  end

  context 'when field is a connection' do
    it 'increases complexity based on arguments' do
      field = Types::BaseField.new(name: 'test', type: GraphQL::Types::String.connection_type, resolver_class: described_class, null: false, max_page_size: 1)

      expect(field.complexity.call({}, { sort: 'foo' }, 1)).to eq 3
      expect(field.complexity.call({}, { search: 'foo' }, 1)).to eq 7
    end

    it 'does not increase complexity when filtering by iids' do
      field = Types::BaseField.new(name: 'test', type: GraphQL::Types::String.connection_type, resolver_class: described_class, null: false, max_page_size: 100)

      expect(field.complexity.call({}, { sort: 'foo' }, 1)).to eq 6
      expect(field.complexity.call({}, { sort: 'foo', iid: 1 }, 1)).to eq 3
      expect(field.complexity.call({}, { sort: 'foo', iids: [1, 2, 3] }, 1)).to eq 3
    end
  end

  describe '#object' do
    it 'returns object' do
      expect_next_instance_of(resolver) do |r|
        expect(r).to receive(:process).with(current_user)
      end

      resolve(resolver, obj: current_user)
    end

    context 'when object is a presenter' do
      it 'returns presented object' do
        expect_next_instance_of(resolver) do |r|
          expect(r).to receive(:process).with(current_user)
        end

        resolve(resolver, obj: UserPresenter.new(current_user))
      end
    end
  end

  describe '#offset_pagination' do
    let(:instance) { resolver_instance(resolver, ctx: query_context) }

    it 'is sugar for OffsetPaginatedRelation.new' do
      expect(instance.offset_pagination(User.none)).to be_a(::Gitlab::Graphql::Pagination::OffsetPaginatedRelation)
    end
  end

  describe '#authorized?' do
    let(:object) { :object }
    let(:scope_validator) { instance_double(::Gitlab::Auth::ScopeValidator) }
    let(:context) { { current_user: current_user, scope_validator: scope_validator } }

    it 'delegates to authorization' do
      expect(resolver.authorization).to be_kind_of(::Gitlab::Graphql::Authorize::ObjectAuthorization)
      expect(resolver.authorization).to receive(:ok?)
        .with(object, current_user, scope_validator: scope_validator)

      resolver.authorized?(object, context)
    end
  end
end
