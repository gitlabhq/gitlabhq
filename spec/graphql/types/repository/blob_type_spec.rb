# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Repository::BlobType do
  specify { expect(described_class.graphql_name).to eq('RepositoryBlob') }

  specify do
    expect(described_class).to have_graphql_fields(
      :id,
      :oid,
      :name,
      :path,
      :web_path,
      :lfs_oid,
      :mode,
      :size,
      :raw_size,
      :raw_blob,
      :raw_text_blob,
      :file_type,
      :edit_blob_path,
      :stored_externally,
      :raw_path,
      :replace_path,
      :simple_viewer,
      :rich_viewer
    )
  end
end
