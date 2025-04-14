# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Elasticsearch::Indexer do
  let(:client) { instance_double(Elasticsearch::Client) }
  let(:indexer) { described_class.new(options, client) }

  it_behaves_like 'an elastic indexer'
end
