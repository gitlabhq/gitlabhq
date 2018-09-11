# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join("db", "importers", "common_metrics_importer.rb")

describe Importers::PrometheusMetric do
  it 'group enum equals ::PrometheusMetric' do
    expect(described_class.groups).to eq(::PrometheusMetric.groups)
  end

  it 'GROUP_TITLES equals ::PrometheusMetric' do
    expect(described_class::GROUP_TITLES).to eq(::PrometheusMetric::GROUP_TITLES)
  end
end

describe Importers::CommonMetricsImporter do
  subject { described_class.new }

  context "does import common_metrics.yml" do
    let(:groups) { subject.content }
    let(:metrics) { groups.map { |group| group['metrics'] }.flatten }
    let(:queries) { metrics.map { |group| group['queries'] }.flatten }
    let(:query_ids) { queries.map { |query| query['id'] } }

    before do
      subject.execute
    end

    it "has the same amount of groups" do
      expect(PrometheusMetric.common.group(:group).count.count).to eq(groups.count)
    end

    it "has the same amount of metrics" do
      expect(PrometheusMetric.common.group(:group, :title).count.count).to eq(metrics.count)
    end

    it "has the same amount of queries" do
      expect(PrometheusMetric.common.count).to eq(queries.count)
    end

    it "does not have duplicate IDs" do
      expect(query_ids).to eq(query_ids.uniq)
    end

    it "imports all IDs" do
      expect(PrometheusMetric.common.pluck(:identifier)).to contain_exactly(*query_ids)
    end
  end

  context "does import common_metrics.yml" do
    it "when executed from outside of the Rails.root" do
      Dir.chdir(Dir.tmpdir) do
        expect { subject.execute }.not_to raise_error
      end

      expect(PrometheusMetric.common).not_to be_empty
    end
  end

  context 'does import properly all fields' do
    let(:query_identifier) { 'response-metric' }
    let(:group) do
      {
        group: 'Response metrics (NGINX Ingress)',
        metrics: [{
          title: "Throughput",
          y_label: "Requests / Sec",
          queries: [{
            id: query_identifier,
            query_range: 'my-query',
            unit: 'my-unit',
            label: 'status code'
          }]
        }]
      }
    end

    before do
      expect(subject).to receive(:content) { [group.deep_stringify_keys] }
    end

    shared_examples 'stores metric' do
      let(:metric) { PrometheusMetric.find_by(identifier: query_identifier) }

      it 'with all data' do
        expect(metric.group).to eq('nginx_ingress')
        expect(metric.title).to eq('Throughput')
        expect(metric.y_label).to eq('Requests / Sec')
        expect(metric.unit).to eq('my-unit')
        expect(metric.legend).to eq('status code')
        expect(metric.query).to eq('my-query')
      end
    end

    context 'if ID is missing' do
      let(:query_identifier) { }

      it 'raises exception' do
        expect { subject.execute }.to raise_error(described_class::MissingQueryId)
      end
    end

    context 'for existing common metric with different ID' do
      let!(:existing_metric) { create(:prometheus_metric, :common, identifier: 'my-existing-metric') }

      before do
        subject.execute
      end

      it_behaves_like 'stores metric' do
        it 'and existing metric is not changed' do
          expect(metric).not_to eq(existing_metric)
        end
      end
    end

    context 'when metric with ID exists ' do
      let!(:existing_metric) { create(:prometheus_metric, :common, identifier: 'response-metric') }

      before do
        subject.execute
      end

      it_behaves_like 'stores metric' do
        it 'and existing metric is changed' do
          expect(metric).to eq(existing_metric)
        end
      end
    end
  end
end
