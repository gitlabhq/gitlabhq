require 'spec_helper'

describe Gitlab::Prometheus::Queries::ValidateQuery do
  let(:client) { double('prometheus_client') }
  let(:query) { 'avg(metric)' }
  subject { described_class.new(client) }

  context 'valid query' do
    before do
      allow(client).to receive(:query).with(query)
    end

    it 'passess query to prometheus' do
      expect(subject.query(query)).to eq(valid: true)

      expect(client).to have_received(:query).with(query)
    end
  end

  context 'invalid query' do
    let(:message) { 'message' }
    before do
      allow(client).to receive(:query).with(query).and_raise(Gitlab::PrometheusClient::QueryError.new(message))
    end

    it 'passes query to prometheus' do
      expect(subject.query(query)).to eq(valid: false, error: message)

      expect(client).to have_received(:query).with(query)
    end
  end
end
