# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Client::QueryLike do
  subject(:query) { described_class.new }

  describe '#to_sql' do
    it { expect { query.to_sql }.to raise_error(NotImplementedError) }
  end

  describe '#to_redacted_sql' do
    it { expect { query.to_redacted_sql }.to raise_error(NotImplementedError) }
  end
end
