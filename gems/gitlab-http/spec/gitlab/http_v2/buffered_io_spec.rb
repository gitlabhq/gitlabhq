# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HTTP_V2::BufferedIo do
  describe '#readuntil' do
    let(:mock_io) { StringIO.new('a') }
    let(:start_time) { Process.clock_gettime(Process::CLOCK_MONOTONIC) }

    before do
      stub_const('Gitlab::HTTP_V2::BufferedIo::HEADER_READ_TIMEOUT', 0.1)
    end

    subject(:readuntil) do
      described_class.new(mock_io).readuntil('a', false, start_time)
    end

    it 'does not raise a timeout error' do
      expect { readuntil }.not_to raise_error
    end

    context 'when the response contains infinitely long headers' do
      before do
        read_counter = 0

        allow(mock_io).to receive(:read_nonblock) do |buffer_size, *_|
          read_counter += 1
          raise 'Test did not raise HeaderReadTimeout' if read_counter > 10

          sleep 0.01
          'H' * buffer_size
        end
      end

      it 'raises a timeout error' do
        expect do
          readuntil
        end.to raise_error(Gitlab::HTTP_V2::HeaderReadTimeout,
          /Request timed out after reading headers for 0\.[0-9]+ seconds/)
      end

      context 'when not passing start_time' do
        subject(:readuntil) do
          described_class.new(mock_io).readuntil('a', false)
        end

        it 'raises a timeout error' do
          expect do
            readuntil
          end.to raise_error(Gitlab::HTTP_V2::HeaderReadTimeout,
            /Request timed out after reading headers for 0\.[0-9]+ seconds/)
        end
      end
    end
  end
end
