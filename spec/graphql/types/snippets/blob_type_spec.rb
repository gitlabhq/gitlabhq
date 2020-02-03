# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['SnippetBlob'] do
  it 'has the correct fields' do
    expected_fields = [:highlighted_data, :raw_path,
                       :size, :binary, :name, :path,
                       :simple_viewer, :rich_viewer,
                       :mode]

    is_expected.to have_graphql_fields(*expected_fields)
  end
end
