# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Net::HTTPResponse patch header read timeout', feature_category: :shared do
  describe '.each_response_header' do
    let(:server_response) do
      <<~HTTP
        Content-Type: text/html
        Header-Two: foo

        Hello World
      HTTP
    end

    before do
      stub_const('Gitlab::HTTP_V2::BufferedIo::HEADER_READ_TIMEOUT', 0.1)
    end

    subject(:each_response_header) { Net::HTTPResponse.each_response_header(socket) { |k, v| } } # rubocop:disable Lint/EmptyBlock

    context 'with Net::BufferedIO' do
      let(:socket) { Net::BufferedIO.new(StringIO.new(server_response)) }

      it 'does not forward start time to the socket' do
        allow(socket).to receive(:readuntil).and_call_original
        expect(socket).to receive(:readuntil).with("\n", true)

        each_response_header
      end

      context 'when the response contains many consecutive spaces' do
        it 'has no regex backtracking issues' do
          expect(socket).to receive(:readuntil).and_return(
            "a: #{' ' * 100_000} b",
            ''
          )

          Timeout.timeout(1) do
            each_response_header
          end
        end
      end
    end

    context 'with Gitlab:HTTP_V2:::BufferedIo' do
      let(:mock_io) { StringIO.new(server_response) }
      let(:socket) { Gitlab::HTTP_V2::BufferedIo.new(mock_io) }

      it 'forwards start time to the socket' do
        allow(socket).to receive(:readuntil).and_call_original
        expect(socket).to receive(:readuntil).with("\n", true, kind_of(Numeric))

        each_response_header
      end

      context 'when the response contains an infinite number of headers' do
        before do
          read_counter = 0

          allow(mock_io).to receive(:read_nonblock) do
            read_counter += 1
            raise 'Test did not raise HeaderReadTimeout' if read_counter > 10

            sleep 0.01
            +"Yet-Another-Header: foo\n"
          end
        end

        it 'raises a timeout error' do
          expect { each_response_header }.to raise_error(Gitlab::HTTP_V2::HeaderReadTimeout,
            /Request timed out after reading headers for 0\.[0-9]+ seconds/)
        end
      end
    end
  end
end
