# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Metrics::DashboardResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  describe '#resolve' do
    subject(:resolve_dashboard) { resolve(described_class, obj: parent_object, args: args, ctx: { current_user: current_user }) }

    let(:args) do
      {
        path: 'config/prometheus/common_metrics.yml'
      }
    end

    context 'for environment' do
      let(:project) { create(:project) }
      let(:parent_object) { create(:environment, project: project) }

      before do
        project.add_developer(current_user)
      end

      it 'use ActiveModel class to find matching dashboard', :aggregate_failures do
        expected_arguments = { project: project, user: current_user, path: args[:path], options: { environment: parent_object } }

        expect(PerformanceMonitoring::PrometheusDashboard).to receive(:find_for).with(expected_arguments).and_return(PerformanceMonitoring::PrometheusDashboard.new)
        expect(resolve_dashboard).to be_instance_of PerformanceMonitoring::PrometheusDashboard
      end

      context 'without parent object' do
        let(:parent_object) { nil }

        it 'returns nil', :aggregate_failures do
          expect(PerformanceMonitoring::PrometheusDashboard).not_to receive(:find_for)
          expect(resolve_dashboard).to be_nil
        end
      end
    end
  end
end
