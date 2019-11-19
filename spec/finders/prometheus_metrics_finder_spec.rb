# frozen_string_literal: true

require 'spec_helper'

describe PrometheusMetricsFinder do
  describe '#execute' do
    let(:finder) { described_class.new(params) }
    let(:params) { {} }

    subject { finder.execute }

    context 'with params' do
      let_it_be(:project) { create(:project) }
      let_it_be(:project_metric) { create(:prometheus_metric, project: project) }
      let_it_be(:common_metric) { create(:prometheus_metric, :common) }
      let_it_be(:unique_metric) do
        create(
          :prometheus_metric,
          :common,
          title: 'Unique title',
          y_label: 'Unique y_label',
          group: :kubernetes,
          identifier: 'identifier',
          created_at: 5.minutes.ago
        )
      end

      context 'with appropriate indexes' do
        before do
          allow_any_instance_of(described_class).to receive(:appropriate_index?).and_return(true)
        end

        context 'with project' do
          let(:params) { { project: project } }

          it { is_expected.to eq([project_metric]) }
        end

        context 'with group' do
          let(:params) { { group: project_metric.group } }

          it { is_expected.to contain_exactly(common_metric, project_metric) }
        end

        context 'with title' do
          let(:params) { { title: project_metric.title } }

          it { is_expected.to contain_exactly(project_metric, common_metric) }
        end

        context 'with y_label' do
          let(:params) { { y_label: project_metric.y_label } }

          it { is_expected.to contain_exactly(project_metric, common_metric) }
        end

        context 'with common' do
          let(:params) { { common: true } }

          it { is_expected.to contain_exactly(common_metric, unique_metric) }
        end

        context 'with ordered' do
          let(:params) { { ordered: true } }

          it { is_expected.to eq([unique_metric, project_metric, common_metric]) }
        end

        context 'with indentifier' do
          let(:params) { { identifier: unique_metric.identifier } }

          it 'raises an error' do
            expect { subject }.to raise_error(
              ArgumentError,
              ':identifier must be scoped to a :project or :common'
            )
          end

          context 'with common' do
            let(:params) { { identifier: unique_metric.identifier, common: true } }

            it { is_expected.to contain_exactly(unique_metric) }
          end

          context 'with id' do
            let(:params) { { id: 14, identifier: 'string' } }

            it 'raises an error' do
              expect { subject }.to raise_error(
                ArgumentError,
                'Only one of :identifier, :id is permitted'
              )
            end
          end
        end

        context 'with id' do
          let(:params) { { id: common_metric.id } }

          it { is_expected.to contain_exactly(common_metric) }
        end

        context 'with multiple params' do
          let(:params) do
            {
              group: project_metric.group,
              title: project_metric.title,
              y_label: project_metric.y_label,
              common: true,
              ordered: true
            }
          end

          it { is_expected.to contain_exactly(common_metric) }
        end
      end

      context 'without an appropriate index' do
        let(:params) do
          {
            title: project_metric.title,
            ordered: true
          }
        end

        it 'raises an error' do
          expect { subject }.to raise_error(
            ArgumentError,
            'An index should exist for params: [:title]'
          )
        end
      end
    end

    context 'without params' do
      it 'raises an error' do
        expect { subject }.to raise_error(
          ArgumentError,
          'Please provide one or more of: [:project, :group, :title, :y_label, :identifier, :id, :common, :ordered]'
        )
      end
    end
  end
end
