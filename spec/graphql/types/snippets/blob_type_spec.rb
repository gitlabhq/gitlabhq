# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['SnippetBlob'] do
  include GraphqlHelpers

  it 'has the correct fields' do
    expected_fields = [:rich_data, :plain_data, :raw_plain_data,
                       :raw_path, :size, :binary, :name, :path,
                       :simple_viewer, :rich_viewer, :mode, :external_storage,
                       :rendered_as_text]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  let_it_be(:nullity) do
    {
      'richData' => be_nullable,
      'plainData' => be_nullable,
      'rawPlainData' => be_nullable,
      'rawPath' => be_non_null,
      'size' => be_non_null,
      'binary' => be_non_null,
      'name' => be_nullable,
      'path' => be_nullable,
      'simpleViewer' => be_non_null,
      'richViewer' => be_nullable,
      'mode' => be_nullable,
      'externalStorage' => be_nullable,
      'renderedAsText' => be_non_null
    }
  end

  let_it_be(:blob) { create(:snippet, :public, :repository).blobs.first }

  shared_examples 'a field from the snippet blob presenter' do |field|
    it "resolves using the presenter", :request_store do
      presented = SnippetBlobPresenter.new(blob)

      expect(resolve_field(field, blob)).to eq(presented.try(field.method_sym))
    end
  end

  described_class.fields.each_value do |field|
    describe field.graphql_name do
      it_behaves_like 'a field from the snippet blob presenter', field
      specify { expect(field.type).to match(nullity.fetch(field.graphql_name)) }
    end
  end
end
