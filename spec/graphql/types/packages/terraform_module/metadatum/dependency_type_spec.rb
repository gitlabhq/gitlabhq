# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['TerraformModuleMetadataDependency'], feature_category: :package_registry do
  it 'includes terraform module metadatum dependency fields' do
    expected_fields = %w[name source version]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  %w[source version].each do |optional_field|
    it "#{optional_field} can be null" do
      expect(described_class.fields[optional_field].type).to be_nullable
    end
  end
end
