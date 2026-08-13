# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::NilResolver, feature_category: :api do
  include GraphqlHelpers

  specify do
    expect(described_class).to have_nullable_graphql_type(::GraphQL::Types::Boolean)
  end

  describe '#resolve' do
    it 'returns nil' do
      result = resolve(described_class, obj: double)

      expect(result).to be_nil
    end
  end
end
