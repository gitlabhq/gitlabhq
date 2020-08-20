# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Tree::TreeEntryType do
  specify { expect(described_class.graphql_name).to eq('TreeEntry') }

  specify { expect(described_class).to have_graphql_fields(:id, :sha, :name, :type, :path, :flat_path, :web_url, :web_path) }
end
