# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SafeRequestStore::NullStore do
  let(:null_store) { described_class.new }

  describe '#store' do
    it 'returns an empty hash' do
      expect(null_store.store).to eq({})
    end
  end

  describe '#active?' do
    it 'returns falsey' do
      expect(null_store.active?).to be_falsey
    end
  end

  describe '#read' do
    it 'returns nil' do
      expect(null_store.read('foo')).to be nil
    end
  end

  describe '#[]' do
    it 'returns nil' do
      expect(null_store['foo']).to be nil
    end
  end

  describe '#write' do
    it 'returns the same value' do
      expect(null_store.write('key', 'value')).to eq('value')
    end
  end

  describe '#[]=' do
    it 'returns the same value' do
      expect(null_store['key'] = 'value').to eq('value')
    end
  end

  describe '#exist?' do
    it 'returns falsey' do
      expect(null_store.exist?('foo')).to be_falsey
    end
  end

  describe '#fetch' do
    it 'returns the block result' do
      expect(null_store.fetch('key') { 'block result' }).to eq('block result') # rubocop:disable Style/RedundantFetchBlock
    end
  end

  describe '#delete' do
    context 'when a block is given' do
      it 'yields the key to the block' do
        expect do |b|
          null_store.delete('foo', &b)
        end.to yield_with_args('foo')
      end

      it 'returns the block result' do
        expect(null_store.delete('foo') { |_key| 'block result' }).to eq('block result')
      end
    end

    context 'when a block is not given' do
      it 'returns nil' do
        expect(null_store.delete('foo')).to be nil
      end
    end
  end
end
