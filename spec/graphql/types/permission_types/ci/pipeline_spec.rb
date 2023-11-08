# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::PermissionTypes::Ci::Pipeline, feature_category: :continuous_integration do
  it 'has expected permission fields' do
    expected_permissions = [
      :admin_pipeline, :destroy_pipeline, :update_pipeline, :cancel_pipeline
    ]

    expect(described_class).to have_graphql_fields(expected_permissions).only
  end
end
