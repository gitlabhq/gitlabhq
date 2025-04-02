# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Opensearch::Indexer do
  let(:client) { instance_double(OpenSearch::Client) }
  let(:indexer) { described_class.new(options, client) }

  it_behaves_like 'an elastic indexer'
end
