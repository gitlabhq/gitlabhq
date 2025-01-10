# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::UserPreferencesType, feature_category: :user_profile do
  specify { expect(described_class.graphql_name).to eq('UserPreferences') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      issues_sort
      use_work_items_view
      visibility_pipeline_id_type
      extensions_marketplace_opt_in_status
      projects_sort
      organization_groups_projects_sort
      organization_groups_projects_display
      timezone
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
