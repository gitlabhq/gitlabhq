# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::PipelineInterface, feature_category: :continuous_integration do
  it 'has the correct name' do
    expect(described_class.graphql_name).to eq('PipelineInterface')
  end

  it 'has the expected fields' do
    expected_fields = %w[id iid path project user]

    expect(described_class.own_fields.size).to eq(expected_fields.size)
    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  describe ".resolve_type" do
    let_it_be(:user) { create(:user) }
    let_it_be(:pipeline) { create(:ci_pipeline) }

    subject { described_class.resolve_type(pipeline, { current_user: user }) }

    it { is_expected.to eq Types::Ci::PipelineType }
  end
end
