# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::BaseResolver do
  include GraphqlHelpers

  let(:resolver) do
    Class.new(described_class) do
      def resolve(**args)
        [args, args]
      end
    end
  end

  describe '.single' do
    it 'returns a subclass from the resolver' do
      expect(resolver.single.superclass).to eq(resolver)
    end

    it 'returns the same subclass every time' do
      expect(resolver.single.object_id).to eq(resolver.single.object_id)
    end

    it 'returns a resolver that gives the first result from the original resolver' do
      result = resolve(resolver.single, args: { test: 1 })

      expect(result).to eq(test: 1)
    end
  end
end
