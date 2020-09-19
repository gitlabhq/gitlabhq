# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Admin::Analytics::InstanceStatistics::MeasurementsResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:admin_user) { create(:user, :admin) }

    let_it_be(:project_measurement_new) { create(:instance_statistics_measurement, :project_count, recorded_at: 2.days.ago) }
    let_it_be(:project_measurement_old) { create(:instance_statistics_measurement, :project_count, recorded_at: 10.days.ago) }

    subject { resolve_measurements({ identifier: 'projects' }, { current_user: current_user }) }

    context 'when requesting project count measurements' do
      context 'as an admin user' do
        let(:current_user) { admin_user }

        it 'returns the records, latest first' do
          expect(subject).to eq([project_measurement_new, project_measurement_old])
        end
      end

      context 'as a non-admin user' do
        let(:current_user) { user }

        it 'raises ResourceNotAvailable error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'as an unauthenticated user' do
        let(:current_user) { nil }

        it 'raises ResourceNotAvailable error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end
    end
  end

  def resolve_measurements(args = {}, context = {})
    resolve(described_class, args: args, ctx: context)
  end
end
