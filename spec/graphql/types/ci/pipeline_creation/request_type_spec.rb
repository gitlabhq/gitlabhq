# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiPipelineCreationRequest'], feature_category: :pipeline_composition do
  include GraphqlHelpers

  it 'has the expected fields' do
    expect(described_class).to have_graphql_fields(:error, :id, :pipeline_id, :status, :user_initiated, :pipeline)
  end

  describe 'pipeline field' do
    subject { described_class.fields['pipeline'] }

    it { is_expected.to have_graphql_type(Types::Ci::PipelineType) }
  end

  describe 'id field' do
    it 'returns the request UUID instead of a global id', :aggregate_failures do
      expect(resolve_field(:id, { 'id' => 'some-uuid' }, object_type: described_class)).to eq('some-uuid')
      expect(resolve_field(:id, {}, object_type: described_class)).to be_nil
    end
  end

  describe 'userInitiated field' do
    it 'treats a missing flag as user initiated', :aggregate_failures do
      expect(resolve_field(:user_initiated, { 'user_initiated' => true }, object_type: described_class)).to be(true)
      expect(resolve_field(:user_initiated, {}, object_type: described_class)).to be(true)
      expect(resolve_field(:user_initiated, { 'user_initiated' => false }, object_type: described_class)).to be(false)
    end
  end
end
