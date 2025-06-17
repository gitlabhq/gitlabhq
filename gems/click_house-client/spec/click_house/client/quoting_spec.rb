# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Client::Quoting do
  describe '.quote' do
    context 'with a String' do
      it 'wraps the string in single quotes and escapes single quotes' do
        expect(described_class.quote('test')).to eq("'test'")
        expect(described_class.quote("test's")).to eq("'test''s'")
      end

      it 'escapes backslashes' do
        expect(described_class.quote('\\')).to eq("'\\\\'")
      end
    end

    context 'with nil' do
      it 'returns NULL' do
        expect(described_class.quote(nil)).to eq('NULL')
      end
    end

    context 'with array' do
      it 'wraps the elements in square brackets and quote the elements' do
        expect(described_class.quote(['test'])).to eq("['test']")
        expect(described_class.quote(['test', nil, 1])).to eq("['test',NULL,1]")
      end
    end
  end
end
