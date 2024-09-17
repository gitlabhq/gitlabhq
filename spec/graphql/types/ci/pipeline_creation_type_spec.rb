# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiPipelineCreationType'], feature_category: :pipeline_composition do
  specify { expect(described_class.graphql_name).to eq('CiPipelineCreationType') }

  it 'has the expected fields' do
    expected_fields = %w[
      pipeline_id
      status
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
