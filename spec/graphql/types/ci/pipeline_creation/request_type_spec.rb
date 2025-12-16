# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiPipelineCreationRequest'], feature_category: :pipeline_composition do
  include GraphqlHelpers

  it 'has the expected fields' do
    expect(described_class).to have_graphql_fields(:error, :pipeline_id, :status, :pipeline)
  end

  describe 'pipeline field' do
    subject { described_class.fields['pipeline'] }

    it { is_expected.to have_graphql_type(Types::Ci::PipelineType) }
  end
end
