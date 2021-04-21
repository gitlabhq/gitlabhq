# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Metrics::Dashboards::AnnotationResolver do
  include GraphqlHelpers

  describe '#resolve' do
    context 'user with developer access' do
      subject(:resolve_annotations) { resolve(described_class, obj: dashboard, args: args, ctx: { current_user: current_user }) }

      let_it_be(:current_user) { create(:user) }
      let_it_be(:environment) { create(:environment) }
      let_it_be(:path) { 'config/prometheus/common_metrics.yml' }

      let(:dashboard) { PerformanceMonitoring::PrometheusDashboard.new(path: path, environment: environment) }
      let(:args) do
        {
          from: 10.minutes.ago,
          to: 5.minutes.ago
        }
      end

      before_all do
        environment.project.add_developer(current_user)
      end

      context 'with annotation records' do
        let_it_be(:annotation_1) { create(:metrics_dashboard_annotation, environment: environment, starting_at: 9.minutes.ago, dashboard_path: path) }

        it 'loads annotations with usage of finder class', :aggregate_failures do
          expect_next_instance_of(::Metrics::Dashboards::AnnotationsFinder, dashboard: dashboard, params: args) do |finder|
            expect(finder).to receive(:execute).and_return [annotation_1]
          end

          expect(resolve_annotations).to eql [annotation_1]
        end

        context 'dashboard is missing' do
          let(:dashboard) { nil }

          it 'returns empty array', :aggregate_failures do
            expect(::Metrics::Dashboards::AnnotationsFinder).not_to receive(:new)

            expect(resolve_annotations).to be_empty
          end
        end

        context 'there are no annotations records' do
          it 'returns empty array' do
            allow_next_instance_of(::Metrics::Dashboards::AnnotationsFinder) do |finder|
              allow(finder).to receive(:execute).and_return []
            end

            expect(resolve_annotations).to be_empty
          end
        end
      end
    end
  end
end
