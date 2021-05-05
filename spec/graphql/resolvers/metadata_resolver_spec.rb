# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::MetadataResolver do
  include GraphqlHelpers

  describe '#resolve' do
    it 'returns version and revision' do
      expect(resolve(described_class)).to have_attributes(
        version: Gitlab::VERSION,
        revision: Gitlab.revision,
        kas: kind_of(InstanceMetadata::Kas))
    end
  end
end
