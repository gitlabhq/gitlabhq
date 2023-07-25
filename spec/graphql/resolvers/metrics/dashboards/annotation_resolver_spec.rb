# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Metrics::Dashboards::AnnotationResolver, feature_category: :metrics do
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

      before do
        stub_feature_flags(remove_monitor_metrics: false)
      end

      context 'with annotation records' do
        context 'when metrics dashboard feature is unavailable' do
          before do
            stub_feature_flags(remove_monitor_metrics: true)
          end

          it 'returns nothing' do
            expect(resolve_annotations).to be_nil
          end
        end

        it 'returns [] all the time' do
          expect(resolve_annotations).to be_empty
        end
      end
    end
  end
end
