# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Tag'], feature_category: :source_code_management do
  specify { expect(described_class.graphql_name).to eq('Tag') }

  specify { expect(described_class).to require_graphql_authorizations(:read_code) }

  it 'contains attributes related to tag' do
    expect(described_class).to have_graphql_fields(
      :name, :message, :commit
    )
  end
end
