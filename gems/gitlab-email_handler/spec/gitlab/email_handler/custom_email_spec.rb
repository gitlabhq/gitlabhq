# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::EmailHandler::CustomEmail, feature_category: :service_desk do
  describe '.base_address' do
    it 'returns a plain custom email unchanged' do
      expect(described_class.base_address('support@acme.com')).to eq('support@acme.com')
    end

    it 'strips the verification subaddress' do
      expect(described_class.base_address('support+verify@acme.com')).to eq('support@acme.com')
    end

    it 'strips a legacy hex reply key' do
      expect(described_class.base_address('support+59d8df8370b7e95c5a49fbf86aeb2c93@acme.com'))
        .to eq('support@acme.com')
    end

    it 'strips a partitioned reply key' do
      expect(described_class.base_address('support+rs-0000000000000000000000abc-rs@acme.com'))
        .to eq('support@acme.com')
    end

    it 'returns nil for a non-email value' do
      expect(described_class.base_address('not-an-email')).to be_nil
    end

    it 'returns nil for a blank value' do
      expect(described_class.base_address('')).to be_nil
    end
  end

  describe '.reply_key' do
    it 'extracts a legacy hex reply key' do
      expect(described_class.reply_key('support+59d8df8370b7e95c5a49fbf86aeb2c93@acme.com'))
        .to eq('59d8df8370b7e95c5a49fbf86aeb2c93')
    end

    it 'extracts a partitioned reply key' do
      expect(described_class.reply_key('support+rs-0000000000000000000000abc-rs@acme.com'))
        .to eq('rs-0000000000000000000000abc-rs')
    end

    it 'returns nil for a plain custom email' do
      expect(described_class.reply_key('support@acme.com')).to be_nil
    end

    it 'returns nil for a verification address' do
      expect(described_class.reply_key('support+verify@acme.com')).to be_nil
    end
  end
end
