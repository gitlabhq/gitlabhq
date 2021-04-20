# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Repository::BlobType do
  specify { expect(described_class.graphql_name).to eq('RepositoryBlob') }

  specify { expect(described_class).to have_graphql_fields(:id, :oid, :name, :path, :web_path, :lfs_oid, :mode) }
end
