# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Snippets::BlobActionEnum do
  specify { expect(described_class.graphql_name).to eq('SnippetBlobActionEnum') }

  it 'exposes all file input action types' do
    expect(described_class.values.keys).to eq(%w[create update delete move])
  end
end
