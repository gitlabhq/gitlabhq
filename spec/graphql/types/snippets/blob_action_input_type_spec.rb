# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Snippets::BlobActionInputType do
  specify { expect(described_class.graphql_name).to eq('SnippetBlobActionInputType') }

  it 'has the correct arguments' do
    expect(described_class.arguments.keys).to match_array(%w[filePath action previousPath content])
  end

  it 'sets the type of action argument to BlobActionEnum' do
    expect(described_class.arguments['action'].type.of_type).to eq(Types::Snippets::BlobActionEnum)
  end
end
