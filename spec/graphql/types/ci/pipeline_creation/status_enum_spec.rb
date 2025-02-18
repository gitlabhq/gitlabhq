# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiPipelineCreationStatus'], feature_category: :fleet_visibility do
  it 'exposes all pipeline creation statuses' do
    expect(described_class.values.keys).to match_array(%w[FAILED IN_PROGRESS SUCCEEDED])
  end
end
