# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['NugetMetadata'] do
  it 'includes nuget metadatum fields' do
    expected_fields = %w[
      id license_url project_url icon_url
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  %w[projectUrl licenseUrl iconUrl].each do |optional_field|
    it "#{optional_field} can be null" do
      expect(described_class.fields[optional_field].type).to be_nullable
    end
  end
end
