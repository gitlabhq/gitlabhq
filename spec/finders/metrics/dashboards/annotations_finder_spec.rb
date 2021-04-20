# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::Dashboards::AnnotationsFinder do
  describe '#execute' do
    subject(:annotations) { described_class.new(dashboard: dashboard, params: params).execute }

    let_it_be(:current_user) { create(:user) }

    let(:path) { 'config/prometheus/common_metrics.yml' }
    let(:params) { {} }
    let(:environment) { create(:environment) }
    let(:dashboard) { PerformanceMonitoring::PrometheusDashboard.new(path: path, environment: environment) }

    context 'there are no annotations records' do
      it 'returns empty array' do
        expect(annotations).to be_empty
      end
    end

    context 'with annotation records' do
      let!(:nine_minutes_old_annotation) { create(:metrics_dashboard_annotation, environment: environment, starting_at: 9.minutes.ago, dashboard_path: path) }
      let!(:fifteen_minutes_old_annotation) { create(:metrics_dashboard_annotation, environment: environment, starting_at: 15.minutes.ago, dashboard_path: path) }
      let!(:just_created_annotation) { create(:metrics_dashboard_annotation, environment: environment, dashboard_path: path) }
      let!(:annotation_for_different_env) { create(:metrics_dashboard_annotation, dashboard_path: path) }
      let!(:annotation_for_different_dashboard) { create(:metrics_dashboard_annotation, dashboard_path: '.gitlab/dashboards/test.yml') }

      it 'loads annotations' do
        expect(annotations).to match_array [fifteen_minutes_old_annotation, nine_minutes_old_annotation, just_created_annotation]
      end

      context 'when the from filter is present' do
        let(:params) do
          {
            from: 14.minutes.ago
          }
        end

        it 'loads only younger annotations' do
          expect(annotations).to match_array [nine_minutes_old_annotation, just_created_annotation]
        end
      end

      context 'when the to filter is present' do
        let(:params) do
          {
            to: 5.minutes.ago
          }
        end

        it 'loads only older annotations' do
          expect(annotations).to match_array [fifteen_minutes_old_annotation, nine_minutes_old_annotation]
        end
      end

      context 'when from and to filters are present' do
        context 'and to is bigger than from' do
          let(:params) do
            {
              from: 14.minutes.ago,
              to: 5.minutes.ago
            }
          end

          it 'loads only annotations assigned to this interval' do
            expect(annotations).to match_array [nine_minutes_old_annotation]
          end
        end

        context 'and from is bigger than to' do
          let(:params) do
            {
              to: 14.minutes.ago,
              from: 5.minutes.ago
            }
          end

          it 'ignores to parameter and returns annotations starting at from filter' do
            expect(annotations).to match_array [just_created_annotation]
          end
        end

        context 'when from or to filters are empty strings' do
          let(:params) do
            {
              from: '',
              to: ''
            }
          end

          it 'ignores this parameters' do
            expect(annotations).to match_array [fifteen_minutes_old_annotation, nine_minutes_old_annotation, just_created_annotation]
          end
        end
      end

      context 'dashboard environment is missing' do
        let(:dashboard) { PerformanceMonitoring::PrometheusDashboard.new(path: path, environment: nil) }

        it 'returns empty relation', :aggregate_failures do
          expect(annotations).to be_kind_of ::ActiveRecord::Relation
          expect(annotations).to be_empty
        end
      end
    end
  end
end
