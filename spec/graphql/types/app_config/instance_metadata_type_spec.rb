# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Metadata'], feature_category: :api do
  specify { expect(described_class.graphql_name).to eq('Metadata') }
  specify { expect(described_class).to require_graphql_authorizations(:read_instance_metadata) }

  it 'exposes the expected fields' do
    expect(described_class).to have_graphql_fields(:enterprise, :feature_flags, :kas, :plan, :revision, :version)
  end
end
