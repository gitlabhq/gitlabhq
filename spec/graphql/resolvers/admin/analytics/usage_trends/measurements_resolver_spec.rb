# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Admin::Analytics::UsageTrends::MeasurementsResolver do
  include GraphqlHelpers

  let_it_be(:admin_user) { create(:user, :admin) }

  let(:current_user) { admin_user }

  describe '#resolve' do
    let_it_be(:user) { create(:user) }

    let_it_be(:project_measurement_new) { create(:usage_trends_measurement, :project_count, recorded_at: 2.days.ago) }
    let_it_be(:project_measurement_old) { create(:usage_trends_measurement, :project_count, recorded_at: 10.days.ago) }

    let(:arguments) { { identifier: 'projects' } }

    subject { resolve_measurements(arguments, { current_user: current_user }) }

    context 'when requesting project count measurements' do
      context 'as an admin user' do
        let(:current_user) { admin_user }

        it 'returns the records, latest first' do
          expect(subject.items).to eq([project_measurement_new, project_measurement_old])
        end
      end

      context 'as a non-admin user' do
        let(:current_user) { user }

        it 'generates a ResourceNotAvailable error' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
            subject
          end
        end
      end

      context 'as an unauthenticated user' do
        let(:current_user) { nil }

        it 'generates a ResourceNotAvailable error' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
            subject
          end
        end
      end

      context 'when filtering by recorded_after and recorded_before' do
        before do
          arguments[:recorded_after] = 4.days.ago
          arguments[:recorded_before] = 1.day.ago
        end

        it { expect(subject.items).to match_array([project_measurement_new]) }

        context 'when "incorrect" values are passed' do
          before do
            arguments[:recorded_after] = 1.day.ago
            arguments[:recorded_before] = 4.days.ago
          end

          it { expect(subject.items).to be_empty }
        end
      end
    end

    context 'when requesting pipeline counts by pipeline status' do
      let_it_be(:pipelines_succeeded_measurement) { create(:usage_trends_measurement, :pipelines_succeeded_count, recorded_at: 2.days.ago) }
      let_it_be(:pipelines_skipped_measurement) { create(:usage_trends_measurement, :pipelines_skipped_count, recorded_at: 2.days.ago) }

      subject { resolve_measurements({ identifier: identifier }, { current_user: current_user }).items }

      context 'filter for pipelines_succeeded' do
        let(:identifier) { 'pipelines_succeeded' }

        it { is_expected.to eq([pipelines_succeeded_measurement]) }
      end

      context 'filter for pipelines_skipped' do
        let(:identifier) { 'pipelines_skipped' }

        it { is_expected.to eq([pipelines_skipped_measurement]) }
      end

      context 'filter for pipelines_failed' do
        let(:identifier) { 'pipelines_failed' }

        it { is_expected.to be_empty }
      end

      context 'filter for pipelines_canceled' do
        let(:identifier) { 'pipelines_canceled' }

        it { is_expected.to be_empty }
      end
    end
  end

  def resolve_measurements(args = {}, context = {})
    resolve(described_class, args: args, ctx: context)
  end
end
