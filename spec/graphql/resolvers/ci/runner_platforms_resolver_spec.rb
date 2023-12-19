# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::RunnerPlatformsResolver, feature_category: :fleet_visibility do
  include GraphqlHelpers

  describe '#resolve' do
    subject(:resolve_subject) { resolve(described_class) }

    it 'returns all possible runner platforms' do
      expect(resolve_subject).to contain_exactly(
        hash_including(name: :linux), hash_including(name: :osx),
        hash_including(name: :windows), hash_including(name: :docker),
        hash_including(name: :kubernetes), hash_including(name: :aws)
      )
    end
  end
end
