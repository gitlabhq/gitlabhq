require 'spec_helper'

describe Resolvers::MetadataResolver do
  include GraphqlHelpers

  describe '#resolve' do
    it 'returns version and revision' do
      expect(resolve(described_class)).to eq(version: Gitlab::VERSION, revision: Gitlab.revision)
    end
  end
end
