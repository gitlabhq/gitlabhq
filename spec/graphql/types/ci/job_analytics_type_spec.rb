# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::JobAnalyticsType, feature_category: :fleet_visibility do
  include GraphqlHelpers

  it 'exposes the expected fields' do
    expected_fields = %i[
      name
      stage
      meanDurationInSeconds
      p95DurationInSeconds
      rateOfSuccess
      rateOfFailed
      rateOfCanceled
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe '#stage' do
    subject(:stage_field) { resolve_field(:stage, object, current_user: user, object_type: described_class) }

    let_it_be(:user) { create(:user) }

    context 'when stage_id is nil' do
      let(:object) { { 'name' => 'Test Job', 'stage_id' => nil } }

      it { is_expected.to be_nil }
    end

    context 'when stage_id is 0' do
      let(:object) { { 'name' => 'Test Job', 'stage_id' => 0 } }

      it { is_expected.to be_nil }
    end

    context 'when stage_id is valid' do
      let_it_be(:stage) { create(:ci_stage) }

      let(:object) { { 'name' => 'Test Job', 'stage_id' => stage.id } }

      it 'fetches and returns the stage' do
        expect(BatchLoader::GraphQL).to receive(:for).with(stage.id).and_call_original
        expect(stage_field.value).to eq(stage)
      end
    end
  end
end
