# frozen_string_literal: true

require 'spec_helper'

describe Types::Tree::TreeType do
  it { expect(described_class.graphql_name).to eq('Tree') }

  it { expect(described_class).to have_graphql_fields(:trees, :submodules, :blobs) }
end
