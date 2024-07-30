# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['TerraformModuleMetadataOutput'], feature_category: :package_registry do
  it 'includes terraform module metadatum output fields' do
    expected_fields = %w[description name]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  %w[description].each do |optional_field|
    it "#{optional_field} can be null" do
      expect(described_class.fields[optional_field].type).to be_nullable
    end
  end
end
