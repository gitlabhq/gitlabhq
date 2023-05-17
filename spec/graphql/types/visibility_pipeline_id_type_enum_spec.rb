# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::VisibilityPipelineIdTypeEnum, feature_category: :user_profile do
  specify { expect(described_class.graphql_name).to eq('VisibilityPipelineIdType') }

  it 'exposes all visibility pipeline id types' do
    expect(described_class.values.keys).to contain_exactly(
      *UserPreference.visibility_pipeline_id_types.keys.map(&:upcase)
    )
  end
end
