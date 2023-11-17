# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiCatalogResourceVersionSort'], feature_category: :pipeline_composition do
  it { expect(described_class.graphql_name).to eq('CiCatalogResourceVersionSort') }

  it 'exposes all the existing catalog resource version sort options' do
    expect(described_class.values.keys).to include(
      *%w[RELEASED_AT_ASC RELEASED_AT_DESC CREATED_ASC CREATED_DESC]
    )
  end
end
