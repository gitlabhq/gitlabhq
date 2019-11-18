# frozen_string_literal: true

require 'spec_helper'

describe Types::Tree::BlobType do
  it { expect(described_class.graphql_name).to eq('Blob') }

  it { expect(described_class).to have_graphql_fields(:id, :sha, :name, :type, :path, :flat_path, :web_url, :lfs_oid) }
end
