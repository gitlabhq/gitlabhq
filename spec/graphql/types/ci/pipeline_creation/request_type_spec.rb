# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiPipelineCreationRequest'], feature_category: :pipeline_composition do
  it 'has the expected fields' do
    expect(described_class).to have_graphql_fields(:error, :pipeline_id, :status)
  end
end
