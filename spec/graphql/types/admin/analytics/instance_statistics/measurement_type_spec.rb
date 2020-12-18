# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['InstanceStatisticsMeasurement'] do
  subject { described_class }

  it { is_expected.to have_graphql_field(:recorded_at) }
  it { is_expected.to have_graphql_field(:identifier) }
  it { is_expected.to have_graphql_field(:count) }

  describe 'authorization' do
    let_it_be(:measurement) { create(:instance_statistics_measurement, :project_count) }
    let(:user) { create(:user) }

    let(:query) do
      <<~GRAPHQL
        query instanceStatisticsMeasurements($identifier: MeasurementIdentifier!) {
          instanceStatisticsMeasurements(identifier: $identifier) {
            nodes {
              count
              identifier
            }
          }
        }
      GRAPHQL
    end

    subject do
      GitlabSchema.execute(
        query,
        variables: { identifier: 'PROJECTS' },
        context: { current_user: user }
      ).to_h
    end

    context 'when the user is not admin' do
      it 'returns no data' do
        expect(subject.dig('data', 'instanceStatisticsMeasurements')).to be_nil
      end
    end

    context 'when user is an admin' do
      let(:user) { create(:user, :admin) }

      before do
        stub_feature_flags(user_mode_in_session: false)
      end

      it 'returns data' do
        expect(subject.dig('data', 'instanceStatisticsMeasurements', 'nodes')).not_to be_empty
      end
    end
  end
end
