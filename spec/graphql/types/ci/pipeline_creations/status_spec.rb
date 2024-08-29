# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiPipelineCreationStatus'], feature_category: :pipeline_composition do
  it 'exposes all pipeline creation status types' do
    expect(described_class.values.keys).to contain_exactly(*%w[CREATING FAILED SUCCEEDED])
  end
end
