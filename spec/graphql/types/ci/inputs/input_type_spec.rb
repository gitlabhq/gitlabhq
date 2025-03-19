# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiInputsInputType'], feature_category: :pipeline_composition do
  specify { expect(described_class.graphql_name).to eq('CiInputsInputType') }

  it 'has the correct arguments' do
    expect(described_class.arguments.keys).to match_array(%w[destroy id name value])
  end
end
