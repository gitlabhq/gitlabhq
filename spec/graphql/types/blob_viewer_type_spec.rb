# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['BlobViewer'] do
  it 'has the correct fields' do
    expected_fields = [:type, :load_async, :too_large, :collapsed,
                       :render_error, :file_type, :loading_partial_name]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
