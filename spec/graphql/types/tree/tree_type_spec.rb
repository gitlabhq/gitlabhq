# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Tree::TreeType do
  specify { expect(described_class.graphql_name).to eq('Tree') }

  specify { expect(described_class).to have_graphql_fields(:trees, :submodules, :blobs, :last_commit) }
end
