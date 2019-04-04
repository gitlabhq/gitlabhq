# frozen_string_literal: true

require 'spec_helper'

describe Types::BaseField do
  context 'when considering complexity' do
    it 'defaults to 1' do
      field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, null: true)

      expect(field.to_graphql.complexity).to eq 1
    end

    it 'has specified value' do
      field = described_class.new(name: 'test', type: GraphQL::STRING_TYPE, null: true, complexity: 12)

      expect(field.to_graphql.complexity).to eq 12
    end
  end
end
