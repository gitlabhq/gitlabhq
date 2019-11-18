# frozen_string_literal: true

require 'spec_helper'

describe Types::Tree::TreeEntryType do
  it { expect(described_class.graphql_name).to eq('TreeEntry') }

  it { expect(described_class).to have_graphql_fields(:id, :sha, :name, :type, :path, :flat_path, :web_url) }
end
