# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Client::Database do
  subject(:database) do
    described_class.new(
      database: 'test_db',
      url: 'http://localhost:3333',
      username: 'user',
      password: 'pass',
      variables: {
        join_use_nulls: 1
      }
    )
  end

  describe '#uri' do
    it 'builds the correct URL' do
      expect(database.uri.to_s).to eq('http://localhost:3333?database=test_db&enable_http_compression=1&join_use_nulls=1')
    end
  end

  describe '#headers' do
    it 'returns the correct headers' do
      expect(database.headers).to eq({
        "X-ClickHouse-Format" => "JSON",
        'X-ClickHouse-User' => 'user',
        'X-ClickHouse-Key' => 'pass'
      })
    end
  end
end
