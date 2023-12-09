# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::UserPreferencesType, feature_category: :user_profile do
  specify { expect(described_class.graphql_name).to eq('UserPreferences') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      issues_sort
      visibility_pipeline_id_type
      use_web_ide_extension_marketplace
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
