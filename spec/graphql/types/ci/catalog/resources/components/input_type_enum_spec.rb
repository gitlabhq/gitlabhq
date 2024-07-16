# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiCatalogResourceComponentInputType'], feature_category: :pipeline_composition do
  it 'exposes all the existing input types' do
    expect(described_class.values.keys).to contain_exactly(
      *%w[ARRAY BOOLEAN NUMBER STRING]
    )
  end
end
