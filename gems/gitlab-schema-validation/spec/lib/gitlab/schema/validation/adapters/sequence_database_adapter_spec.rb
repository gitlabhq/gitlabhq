# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Adapters::SequenceDatabaseAdapter do
  let(:query_result) do
    {
      'schema' => 'public',
      'sequence_name' => 'users_id_seq',
      'owned_by_column' => 'users.id',
      'user_owner' => 'gitlab',
      'start_value' => '1',
      'increment_by' => '1',
      'min_value' => '1',
      'max_value' => '9223372036854775807',
      'cycle' => false
    }
  end

  subject(:adapter) { described_class.new(query_result) }

  describe '#name' do
    it 'returns formatted sequence name with schema' do
      expect(adapter.name).to eq('public.users_id_seq')
    end

    context 'when schema or sequence_name is nil' do
      let(:query_result) { { 'schema' => nil, 'sequence_name' => 'test_seq' } }

      it 'defaults to public schema' do
        expect(adapter.name).to eq('public.test_seq')
      end
    end

    context 'when both schema and sequence_name are missing' do
      let(:query_result) { {} }

      it 'returns nil' do
        expect(adapter.name).to be_nil
      end
    end
  end

  describe '#column_owner' do
    it 'returns formatted column owner with schema' do
      expect(adapter.column_owner).to eq('public.users.id')
    end

    context 'when owned_by_column contains table.column format' do
      let(:query_result) do
        {
          'schema' => 'analytics',
          'owned_by_column' => 'events.event_id'
        }
      end

      it 'prepends schema correctly' do
        expect(adapter.column_owner).to eq('analytics.events.event_id')
      end
    end

    context 'when schema or owned_by_column is nil' do
      let(:query_result) { { 'schema' => 'test', 'owned_by_column' => nil } }

      it 'returns nil' do
        expect(adapter.column_owner).to be_nil
      end
    end
  end

  describe '#user_owner' do
    it 'returns the user owner' do
      expect(adapter.user_owner).to eq('gitlab')
    end

    context 'when user_owner is nil' do
      let(:query_result) { { 'user_owner' => nil } }

      it 'returns nil' do
        expect(adapter.user_owner).to be_nil
      end
    end

    context 'when user_owner is missing' do
      let(:query_result) { {} }

      it 'returns nil' do
        expect(adapter.user_owner).to be_nil
      end
    end
  end

  describe '#start_value' do
    it 'returns the start value' do
      expect(adapter.start_value).to eq('1')
    end

    context 'when start_value is different' do
      let(:query_result) { { 'start_value' => '100' } }

      it 'returns the correct value' do
        expect(adapter.start_value).to eq('100')
      end
    end
  end

  describe '#increment_by' do
    it 'returns the increment value' do
      expect(adapter.increment_by).to eq('1')
    end

    context 'when increment_by is different' do
      let(:query_result) { { 'increment_by' => '5' } }

      it 'returns the correct value' do
        expect(adapter.increment_by).to eq('5')
      end
    end
  end

  describe '#min_value' do
    it 'returns the minimum value' do
      expect(adapter.min_value).to eq('1')
    end

    context 'when min_value is different' do
      let(:query_result) { { 'min_value' => '0' } }

      it 'returns the correct value' do
        expect(adapter.min_value).to eq('0')
      end
    end
  end

  describe '#max_value' do
    it 'returns the maximum value' do
      expect(adapter.max_value).to eq('9223372036854775807')
    end

    context 'when max_value is different' do
      let(:query_result) { { 'max_value' => '1000' } }

      it 'returns the correct value' do
        expect(adapter.max_value).to eq('1000')
      end
    end
  end

  describe '#cycle' do
    it 'returns the cycle value' do
      expect(adapter.cycle).to be(false)
    end

    context 'when cycle is true' do
      let(:query_result) { { 'cycle' => true } }

      it 'returns true' do
        expect(adapter.cycle).to be(true)
      end
    end

    context 'when cycle is nil' do
      let(:query_result) { { 'cycle' => nil } }

      it 'returns nil' do
        expect(adapter.cycle).to be_nil
      end
    end
  end
end
