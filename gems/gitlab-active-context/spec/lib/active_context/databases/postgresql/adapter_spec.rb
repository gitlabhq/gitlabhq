# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Postgresql::Adapter do
  let(:options) do
    {
      host: 'localhost',
      port: 5432,
      database: 'test_db',
      username: 'user',
      password: 'pass'
    }
  end

  subject(:adapter) { described_class.new(options) }

  it 'delegates search to client' do
    query = ActiveContext::Query.filter(foo: :bar)
    expect(adapter.client).to receive(:search).with(query)

    adapter.search(query)
  end
end
