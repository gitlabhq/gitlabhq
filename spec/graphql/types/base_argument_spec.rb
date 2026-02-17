# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::BaseArgument, feature_category: :api do
  include_examples 'Gitlab-style deprecations' do
    let_it_be(:field) do
      Types::BaseField.new(name: 'field', type: String, null: true)
    end

    def subject(args = {})
      base_args = { name: 'test', type: String, required: false, owner: field }
      described_class.new(**base_args.merge(args))
    end
  end

  describe 'array size validation' do
    let_it_be(:user) { create(:user) }
    let_it_be(:field) { Types::BaseField.new(name: 'field', type: String, null: true) }

    describe 'automatic validation detection' do
      context 'when argument is an array type without explicit validates' do
        it 'adds automatic validation via prepare option' do
          argument = described_class.new(:test_array, [String], required: false, owner: field)

          expect(argument.instance_variable_get(:@prepare)).to be_present
        end
      end

      context 'when argument has explicit validates: { length: { maximum: ... } }' do
        it 'does not add automatic validation' do
          argument = described_class.new(
            :test_array, [String], required: false, owner: field, validates: { length: { maximum: 50 } }
          )

          # Check that add_validation? returns false
          expect(argument.send(:add_validation?, [String], { length: { maximum: 50 } })).to be false
        end
      end

      context 'when argument is not an array type' do
        it 'does not add automatic validation' do
          argument = described_class.new(:test_string, String, required: false, owner: field)

          expect(argument.send(:add_validation?, String, nil)).to be false
        end
      end
    end

    describe 'helper methods' do
      let(:argument) { described_class.new(:test, [String], required: false, owner: field) }

      describe '#array_type?' do
        it 'returns true for array types' do
          expect(argument.send(:array_type?, [String])).to be true
        end

        it 'returns false for non-array types' do
          expect(argument.send(:array_type?, String)).to be false
        end

        it 'returns false for nil' do
          expect(argument.send(:array_type?, nil)).to be false
        end
      end

      describe '#has_length_validation_in_options?' do
        it 'returns false when validates is nil' do
          expect(argument.send(:has_length_validation_in_options?, nil)).to be false
        end

        it 'returns true when validates: { length: { maximum: ... } } is provided' do
          validates_option = { length: { maximum: 50 } }
          expect(argument.send(:has_length_validation_in_options?, validates_option)).to be true
        end

        it 'returns true when validates: { length: { minimum: ..., maximum: ... } } is provided' do
          validates_option = { length: { minimum: 1, maximum: 50 } }
          expect(argument.send(:has_length_validation_in_options?, validates_option)).to be true
        end

        it 'returns false when validates has other options but not length' do
          validates_option = { presence: true }
          expect(argument.send(:has_length_validation_in_options?, validates_option)).to be false
        end

        it 'returns false when validates is not a hash' do
          expect(argument.send(:has_length_validation_in_options?, "not a hash")).to be false
        end
      end
    end

    describe 'integration with GraphQL schema' do
      let(:test_resolver) do
        Class.new(Resolvers::BaseResolver) do
          type [GraphQL::Types::String], null: true

          # No explicit validation - should use automatic 100-item limit
          argument :auto_validated_items, [GraphQL::Types::String],
            required: false,
            description: 'Items with automatic validation'

          # Explicit validation - should use 30-item limit from GraphQL-Ruby
          argument :explicit_validated_items, [GraphQL::Types::String],
            required: false,
            validates: { length: { maximum: 30 } },
            description: 'Items with explicit validation'

          # No explicit validation with prepare block
          argument :prepared_items, [GraphQL::Types::String],
            required: false,
            description: "Items with prepared block",
            prepare: ->(items, _) do
              items
            end

          # explicit validation/error handling with prepare block
          argument :prepared_items_with_err, [GraphQL::Types::String],
            required: false,
            description: "Items with prepared block raising error",
            prepare: ->(items, _) do
              raise Gitlab::Graphql::Errors::ArgumentError, "Too many items" if items.size > 10

              items
            end

          def resolve(
            auto_validated_items: nil, explicit_validated_items: nil, prepared_items: nil,
            prepared_items_with_err: nil)
            auto_validated_items || explicit_validated_items ||
              prepared_items || prepared_items_with_err
          end
        end
      end

      let(:query_type) do
        resolver = test_resolver

        Class.new(Types::BaseObject) do
          graphql_name 'Query'
          field :test_field, resolver: resolver
        end
      end

      let(:schema) do
        query = query_type

        Class.new(GraphQL::Schema) do
          query(query)
        end
      end

      context 'with automatic validation' do
        it 'allows 100 items' do
          items = Array.new(100) { |i| "item#{i}" }
          query_string = <<~GQL
            query {
              testField(autoValidatedItems: #{items.to_json})
            }
          GQL

          result = schema.execute(query_string, context: { current_user: user })

          expect(result['errors']).to be_nil
          expect(result.dig('data', 'testField')).to eq(items)
        end

        it 'rejects 101 items with custom error message' do
          items = Array.new(101) { |i| "item#{i}" }
          query_string = <<~GQL
            query {
              testField(autoValidatedItems: #{items.to_json})
            }
          GQL

          expect(::Gitlab::GraphqlLogger).to receive(:info).with(
            hash_including(
              {
                array_argument_name: "#autoValidatedItems",
                message: "Array argument over the size limit",
                operation_name: nil,
                value_size: 101
              }
            )
          )
          schema.execute(query_string, context: { current_user: user })
        end
      end

      context 'with prepared items' do
        it 'allows items in limit' do
          items = Array.new(10) { |i| "item#{i}" }
          query_string = <<~GQL
            query {
              testField(preparedItems: #{items.to_json})
            }
          GQL

          result = schema.execute(query_string, context: { current_user: user })

          expect(result['errors']).to be_nil
          expect(result.dig('data', 'testField')).to eq(items)
        end

        it 'rejects over the limit' do
          items = Array.new(101) { |i| "item#{i}" }
          query_string = <<~GQL
            query {
              testField(preparedItems: #{items.to_json})
            }
          GQL

          expect(::Gitlab::GraphqlLogger).to receive(:info).with(
            hash_including(
              {
                array_argument_name: "#preparedItems",
                message: "Array argument over the size limit",
                operation_name: nil,
                value_size: 101
              }
            )
          )
          schema.execute(query_string, context: { current_user: user })
        end
      end

      context 'with prepared items raising error' do
        it 'allows items in limit' do
          items = Array.new(5) { |i| "item#{i}" }
          query_string = <<~GQL
            query {
              testField(preparedItemsWithErr: #{items.to_json})
            }
          GQL

          result = schema.execute(query_string, context: { current_user: user })

          expect(result['errors']).to be_nil
          expect(result.dig('data', 'testField')).to eq(items)
        end

        it 'rejects items over the limit' do
          items = Array.new(101) { |i| "item#{i}" }
          query_string = <<~GQL
            query {
              testField(preparedItemsWithErr: #{items.to_json})
            }
          GQL

          expect(::Gitlab::GraphqlLogger).not_to receive(:info)

          result = schema.execute(query_string, context: { current_user: user })

          expect(result['errors']).not_to be_nil
          expect(result.dig('errors', 0, 'message')).to eq('Too many items')
        end
      end

      context 'with explicit validation' do
        it 'allows 30 items' do
          items = Array.new(30) { |i| "item#{i}" }
          query_string = <<~GQL
            query {
              testField(explicitValidatedItems: #{items.to_json})
            }
          GQL

          result = schema.execute(query_string, context: { current_user: user })

          expect(result['errors']).to be_nil
          expect(result.dig('data', 'testField')).to eq(items)
        end

        it 'rejects 31 items with GraphQL-Ruby error message' do
          items = Array.new(31) { |i| "item#{i}" }
          query_string = <<~GQL
            query {
              testField(explicitValidatedItems: #{items.to_json})
            }
          GQL

          result = schema.execute(query_string, context: { current_user: user })

          expect(result['errors']).not_to be_nil
          # GraphQL-Ruby's built-in validation error format (consistent with existing codebase)
          expect(result.dig('errors', 0, 'message')).to eq('explicitValidatedItems is too long (maximum is 30)')
          expect(result.dig('data', 'testField')).to be_nil
        end

        it 'does not trigger automatic validation for arrays between explicit and automatic limits' do
          # 75 items: exceeds explicit limit (30) but within automatic limit (100)
          items = Array.new(75) { |i| "item#{i}" }
          query_string = <<~GQL
            query {
              testField(explicitValidatedItems: #{items.to_json})
            }
          GQL

          result = schema.execute(query_string, context: { current_user: user })

          # Should only get GraphQL-Ruby error, not our custom error
          expect(result['errors']).not_to be_nil
          expect(result.dig('errors', 0, 'message')).to eq('explicitValidatedItems is too long (maximum is 30)')
          expect(result.dig('errors', 0, 'message')).not_to include('cannot accept more than 100 items')
        end
      end
    end
  end
end
