# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Repository::BlobType, feature_category: :source_code_management do
  include GraphqlHelpers

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
      :base64_encoded_blob,
      :raw_text_blob,
      :file_type,
      :edit_blob_path,
      :stored_externally,
      :external_storage,
      :raw_path,
      :replace_path,
      :pipeline_editor_path,
      :gitpod_blob_url,
      :find_file_path,
      :blame_path,
      :blame,
      :history_path,
      :permalink_path,
      :environment_formatted_external_url,
      :environment_external_url_for_route_map,
      :code_navigation_path,
      :project_blob_path_root,
      :simple_viewer,
      :rich_viewer,
      :plain_data,
      :can_modify_blob,
      :can_modify_blob_with_web_ide,
      :can_current_user_push_to_branch,
      :archived,
      :ide_edit_path,
      :external_storage_url,
      :fork_and_edit_path,
      :ide_fork_and_edit_path,
      :fork_and_view_path,
      :language
    ).at_least
  end

  it 'handles blobs of huge size', :aggregate_failures do
    huge_blob = Blob.new(double)
    size = 10**10
    allow(huge_blob).to receive_messages({ size: size, raw_size: size })

    expect(resolve_field(:raw_size, huge_blob)).to eq(size)
    expect(resolve_field(:size, huge_blob)).to eq(size)
  end
end
