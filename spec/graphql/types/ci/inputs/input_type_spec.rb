# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiInputsInput'], feature_category: :pipeline_composition do
  specify { expect(described_class.graphql_name).to eq('CiInputsInput') }

  it 'has the correct arguments' do
    expect(described_class.arguments.keys).to match_array(%w[destroy name value])
  end
end
