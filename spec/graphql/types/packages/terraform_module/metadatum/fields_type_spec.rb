# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['TerraformModuleMetadataFields'], feature_category: :package_registry do
  it 'includes terraform module metadatum fields' do
    expected_fields = %w[root submodules examples]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  %w[examples submodules].each do |optional_field|
    it "#{optional_field} can be null" do
      expect(described_class.fields[optional_field].type).to be_nullable
    end
  end
end
