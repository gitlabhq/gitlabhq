# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::JobAnalyticsType, feature_category: :fleet_visibility do
  include GraphqlHelpers

  it 'exposes the expected fields' do
    expected_fields = %i[
      name
      stage_name
      statistics
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'field resolvers' do
    subject(:resolved_field) { resolve_field(field_name, object, current_user: user, object_type: described_class) }

    let_it_be(:user) { create(:user) }

    describe '#stage_name' do
      let(:field_name) { :stage_name }

      context 'when stage_name is nil' do
        let(:object) { { 'name' => 'Test Job', 'stage_name' => nil } }

        it { is_expected.to be_nil }
      end

      context 'when stage_name is empty string' do
        let(:object) { { 'name' => 'Test Job', 'stage_name' => '' } }

        it { is_expected.to eq('') }
      end

      context 'when stage_name is valid' do
        let(:object) { { 'name' => 'Test Job', 'stage_name' => 'build' } }

        it { is_expected.to eq('build') }
      end
    end

    describe '#statistics' do
      let(:field_name) { :statistics }

      let(:object) do
        {
          'name' => 'Test Job',
          'rate_of_success' => 75.0,
          'total_count' => 20
        }
      end

      it 'returns the object' do
        is_expected.to eq(object)
      end
    end
  end
end
