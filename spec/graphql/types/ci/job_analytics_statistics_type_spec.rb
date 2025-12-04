# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::JobAnalyticsStatisticsType, feature_category: :fleet_visibility do
  include GraphqlHelpers

  it 'exposes the expected fields' do
    expected_fields = %i[count rate duration_statistics]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'field resolvers' do
    subject(:resolved_field) do
      resolve_field(field_name, object, args: args, current_user: current_user, object_type: described_class)
    end

    let_it_be(:current_user) { create(:user) }

    let(:args) { {} }
    let(:object) do
      {
        rate_of_success: 75.0,
        rate_of_failed: 20.0,
        rate_of_canceled: 5.0,
        count_success: 15,
        count_failed: 4,
        count_canceled: 1,
        total_count: 20,
        mean: 10.5,
        p50: 8.0,
        p95: 15.0
      }
    end

    describe '#count' do
      let(:field_name) { :count }

      context 'with status: SUCCESS' do
        let(:args) { { status: :SUCCESS } }

        it { is_expected.to eq(object[:count_success]) }
      end

      context 'with status: FAILED' do
        let(:args) { { status: :FAILED } }

        it { is_expected.to eq(object[:count_failed]) }
      end

      context 'without status argument (nil)' do
        let(:args) { { status: nil } }

        it { is_expected.to eq(object[:total_count]) }
      end

      context 'when status data is missing' do
        let(:object) { {} }
        let(:args) { { status: :SUCCESS } }

        it { is_expected.to be_nil }
      end
    end

    describe '#rate' do
      let(:field_name) { :rate }

      context 'with status: SUCCESS' do
        let(:args) { { status: :SUCCESS } }

        it { is_expected.to eq(object[:rate_of_success]) }
      end

      context 'with status: FAILED' do
        let(:args) { { status: :FAILED } }

        it { is_expected.to eq(object[:rate_of_failed]) }
      end

      context 'without status argument (nil)' do
        let(:args) { { status: nil } }

        it { is_expected.to eq(100.0) }
      end

      context 'when status data is missing' do
        let(:object) { {} }

        let(:args) { { status: :SUCCESS } }

        it { is_expected.to be_nil }
      end
    end

    describe '#duration_statistics' do
      let(:field_name) { :duration_statistics }

      it { is_expected.to eq(object) }
    end
  end
end
