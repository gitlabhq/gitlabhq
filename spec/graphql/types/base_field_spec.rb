# frozen_string_literal: true

require 'spec_helper'

describe Types::BaseField do
  context 'when considering complexity' do
    let(:resolver) do
      Class.new(described_class) do
        def self.resolver_complexity(args)
          2 if args[:foo]
        end

        def self.complexity_multiplier(args)
          0.01
        end
      end
    end

    it 'defaults to 1' do
      field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, null: true)

      expect(field.to_graphql.complexity).to eq 1
    end

    it 'has specified value' do
      field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, null: true, complexity: 12)

      expect(field.to_graphql.complexity).to eq 12
    end

    it 'sets complexity depending on arguments for resolvers' do
      field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, resolver_class: resolver, max_page_size: 100, null: true)

      expect(field.to_graphql.complexity.call({}, {}, 2)).to eq 4
      expect(field.to_graphql.complexity.call({}, { first: 50 }, 2)).to eq 3
    end

    it 'sets complexity depending on number load limits for resolvers' do
      field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, resolver_class: resolver, max_page_size: 100, null: true)

      expect(field.to_graphql.complexity.call({}, { first: 1 }, 2)).to eq 2
      expect(field.to_graphql.complexity.call({}, { first: 1, foo: true }, 2)).to eq 4
    end
  end
end
