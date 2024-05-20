# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::BaseField, feature_category: :api do
  describe 'authorized?' do
    let(:object) { double }
    let(:current_user) { nil }
    let(:ctx) { { current_user: current_user } }

    it 'defaults to true' do
      field = described_class.new(name: 'test', type: GraphQL::Types::String, null: true)

      expect(field).to be_authorized(object, nil, ctx)
    end

    it 'tests the field authorization, if provided' do
      field = described_class.new(name: 'test', type: GraphQL::Types::String, null: true, authorize: :foo)

      expect(Ability).to receive(:allowed?).with(current_user, :foo, object).and_return(false)

      expect(field).not_to be_authorized(object, nil, ctx)
    end

    it 'tests the field authorization, if provided, when it succeeds' do
      field = described_class.new(name: 'test', type: GraphQL::Types::String, null: true, authorize: :foo)

      expect(Ability).to receive(:allowed?).with(current_user, :foo, object).and_return(true)

      expect(field).to be_authorized(object, nil, ctx)
    end

    it 'only tests the resolver authorization if it authorizes_object?' do
      resolver = Class.new(Resolvers::BaseResolver)

      field = described_class.new(
        name: 'test', type: GraphQL::Types::String, null: true, resolver_class: resolver
      )

      expect(field).to be_authorized(object, nil, ctx)
    end

    it 'tests the resolver authorization, if provided' do
      resolver = Class.new(Resolvers::BaseResolver) do
        include Gitlab::Graphql::Authorize::AuthorizeResource

        authorizes_object!
      end

      field = described_class.new(
        name: 'test', type: GraphQL::Types::String, null: true, resolver_class: resolver
      )

      expect(resolver).to receive(:authorized?).with(object, ctx).and_return(false)

      expect(field).not_to be_authorized(object, nil, ctx)
    end

    it 'tests field authorization before resolver authorization, when field auth fails' do
      resolver = Class.new(Resolvers::BaseResolver) do
        include Gitlab::Graphql::Authorize::AuthorizeResource

        authorizes_object!
      end

      field = described_class.new(
        name: 'test',
        type: GraphQL::Types::String,
        null: true,
        authorize: :foo,
        resolver_class: resolver
      )

      expect(Ability).to receive(:allowed?).with(current_user, :foo, object).and_return(false)
      expect(resolver).not_to receive(:authorized?)

      expect(field).not_to be_authorized(object, nil, ctx)
    end

    it 'tests field authorization before resolver authorization, when field auth succeeds' do
      resolver = Class.new(Resolvers::BaseResolver) do
        include Gitlab::Graphql::Authorize::AuthorizeResource

        authorizes_object!
      end

      field = described_class.new(
        name: 'test',
        type: GraphQL::Types::String,
        null: true,
        authorize: :foo,
        resolver_class: resolver
      )

      expect(Ability).to receive(:allowed?).with(current_user, :foo, object).and_return(true)
      expect(resolver).to receive(:authorized?).with(object, ctx).and_return(false)

      expect(field).not_to be_authorized(object, nil, ctx)
    end
  end

  context 'when considering complexity' do
    let(:resolver) do
      Class.new(Resolvers::BaseResolver) do
        def self.resolver_complexity(args, child_complexity:)
          2 if args[:foo]
        end

        def self.complexity_multiplier(args)
          0.01
        end
      end
    end

    it 'defaults to 1' do
      field = described_class.new(name: 'test', type: GraphQL::Types::String, null: true)

      expect(field.complexity).to eq 1
    end

    describe '#base_complexity' do
      context 'with no gitaly calls' do
        it 'defaults to 1' do
          field = described_class.new(name: 'test', type: GraphQL::Types::String, null: true)

          expect(field.base_complexity).to eq 1
        end
      end

      context 'with a gitaly call' do
        it 'adds 1 to the default value' do
          field = described_class.new(name: 'test', type: GraphQL::Types::String, null: true, calls_gitaly: true)

          expect(field.base_complexity).to eq 2
        end
      end
    end

    it 'has specified value' do
      field = described_class.new(name: 'test', type: GraphQL::Types::String, null: true, complexity: 12)

      expect(field.complexity).to eq 12
    end

    context 'when field has a resolver' do
      context 'when a valid complexity is already set' do
        let(:field) { described_class.new(name: 'test', type: GraphQL::Types::String.connection_type, resolver_class: resolver, complexity: 2, max_page_size: 100, null: true) }

        it 'uses this complexity' do
          expect(field.complexity).to eq 2
        end
      end

      context 'and is a connection' do
        let(:field) { described_class.new(name: 'test', type: GraphQL::Types::String.connection_type, resolver_class: resolver, max_page_size: 100, null: true) }

        it 'sets complexity depending on arguments for resolvers' do
          expect(field.complexity.call({}, {}, 2)).to eq 4
          expect(field.complexity.call({}, { first: 50 }, 2)).to eq 3
        end

        it 'sets complexity depending on number load limits for resolvers' do
          expect(field.complexity.call({}, { first: 1 }, 2)).to eq 2
          expect(field.complexity.call({}, { first: 1, foo: true }, 2)).to eq 4
        end
      end

      context 'and is not a connection' do
        it 'sets complexity as normal' do
          field = described_class.new(name: 'test', type: GraphQL::Types::String, resolver_class: resolver, max_page_size: 100, null: true)

          expect(field.complexity.call({}, {}, 2)).to eq 2
          expect(field.complexity.call({}, { first: 50 }, 2)).to eq 2
        end
      end
    end

    context 'calls_gitaly' do
      context 'for fields with a resolver' do
        it 'adds 1 if true' do
          with_gitaly_field = described_class.new(name: 'test', type: GraphQL::Types::String, resolver_class: resolver, null: true, calls_gitaly: true)
          without_gitaly_field = described_class.new(name: 'test', type: GraphQL::Types::String, resolver_class: resolver, null: true)
          base_result = without_gitaly_field.complexity.call({}, {}, 2)

          expect(with_gitaly_field.complexity.call({}, {}, 2)).to eq base_result + 1
        end
      end

      context 'for fields without a resolver' do
        it 'adds 1 if true' do
          field = described_class.new(name: 'test', type: GraphQL::Types::String, null: true, calls_gitaly: true)

          expect(field.complexity).to eq 2
        end
      end

      it 'defaults to false' do
        field = described_class.new(name: 'test', type: GraphQL::Types::String, null: true)

        expect(field.base_complexity).to eq Types::BaseField::DEFAULT_COMPLEXITY
      end

      context 'with declared constant complexity value' do
        it 'has complexity set to that constant' do
          field = described_class.new(name: 'test', type: GraphQL::Types::String, null: true, complexity: 12)

          expect(field.complexity).to eq 12
        end

        it 'does not raise an error even with Gitaly calls' do
          allow(Gitlab::GitalyClient).to receive(:get_request_count).and_return([0, 1])
          field = described_class.new(name: 'test', type: GraphQL::Types::String, null: true, complexity: 12)

          expect(field.complexity).to eq 12
        end
      end
    end
  end

  describe '#resolve' do
    context "late_extensions is given" do
      it 'registers the late extensions after the regular extensions' do
        extension_class = Class.new(GraphQL::Schema::Field::ConnectionExtension)
        field = described_class.new(name: 'test', type: GraphQL::Types::String.connection_type, null: true, late_extensions: [extension_class])

        expect(field.extensions.last.class).to be(extension_class)
      end
    end
  end

  include_examples 'Gitlab-style deprecations' do
    def subject(args = {})
      base_args = { name: 'test', type: GraphQL::Types::String, null: true }

      described_class.new(**base_args.merge(args))
    end
  end

  describe '#field_authorized?' do
    let(:object) { :object }
    let(:scope_validator) { instance_double(::Gitlab::Auth::ScopeValidator) }
    let(:user) { :user }
    let(:context) { { current_user: user, scope_validator: scope_validator } }

    it 'delegates to authorization providing the scopes' do
      expect_next_instance_of(::Gitlab::Graphql::Authorize::ObjectAuthorization) do |authorization|
        expect(authorization).to receive(:ok?)
          .with(object, user, scope_validator: scope_validator)
        expect(authorization.permitted_scopes).to eq([:api, :foobar_scope])
      end

      field = described_class.new(name: 'test', type: GraphQL::Types::String, null: true, scopes: [:api, :foobar_scope])
      field.authorized?(object, nil, context)
    end
  end
end
