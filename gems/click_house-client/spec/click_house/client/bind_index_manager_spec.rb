# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Client::BindIndexManager do
  describe '#next_bind_str' do
    context 'when initialized without a start index' do
      let(:bind_manager) { described_class.new }

      it 'starts from index 1 by default' do
        expect(bind_manager.next_bind_str).to eq('$1')
      end

      it 'increments the bind string on subsequent calls' do
        bind_manager.next_bind_str
        expect(bind_manager.next_bind_str).to eq('$2')
      end
    end

    context 'when initialized with a start index' do
      let(:bind_manager) { described_class.new(2) }

      it 'starts from the given index' do
        expect(bind_manager.next_bind_str).to eq('$2')
      end

      it 'increments the bind string on subsequent calls' do
        bind_manager.next_bind_str
        expect(bind_manager.next_bind_str).to eq('$3')
      end
    end
  end
end
