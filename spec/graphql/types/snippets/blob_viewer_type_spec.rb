# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['SnippetBlobViewer'] do
  it 'has the correct fields' do
    expected_fields = [:type, :load_async, :too_large, :collapsed,
                       :render_error, :file_type, :loading_partial_name]

    is_expected.to have_graphql_fields(*expected_fields)
  end
end
