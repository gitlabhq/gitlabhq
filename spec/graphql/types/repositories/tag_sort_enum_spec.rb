# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['TagSort'], feature_category: :source_code_management do
  specify { expect(described_class.graphql_name).to eq('TagSort') }

  it 'exposes all the tag sort orders' do
    expect(described_class.values.keys).to match_array(
      %w[NAME_ASC NAME_DESC UPDATED_ASC UPDATED_DESC VERSION_ASC VERSION_DESC]
    )
  end

  it 'maps to the sort keys accepted by TagsFinder' do
    expect(described_class.values.transform_values(&:value)).to eq(
      'NAME_ASC' => 'name_asc',
      'NAME_DESC' => 'name_desc',
      'UPDATED_ASC' => 'updated_asc',
      'UPDATED_DESC' => 'updated_desc',
      'VERSION_ASC' => 'version_asc',
      'VERSION_DESC' => 'version_desc'
    )
  end
end
