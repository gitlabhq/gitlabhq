# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiInputsType'], feature_category: :pipeline_composition do
  it 'exposes all the existing input types' do
    expect(described_class.values.keys).to match_array(%w[ARRAY BOOLEAN NUMBER STRING])
  end
end
