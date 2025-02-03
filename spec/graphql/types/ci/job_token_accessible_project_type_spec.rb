# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiJobTokenAccessibleProject'], feature_category: :continuous_integration do
  specify { expect(described_class.graphql_name).to eq('CiJobTokenAccessibleProject') }

  it 'has the correct fields' do
    expected_fields = [:id, :name, :path, :full_path, :web_url, :avatar_url]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
