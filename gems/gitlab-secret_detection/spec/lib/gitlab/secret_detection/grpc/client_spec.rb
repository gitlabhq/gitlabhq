# frozen_string_literal: true

require 'time'
require_relative '../../../../spec_helper'

SDGRPC = Gitlab::SecretDetection::GRPC
GRPCStatus = SDGRPC::ScanResponse::Status
SD = Gitlab::SecretDetection

RSpec.describe Gitlab::SecretDetection::GRPC::Client do
  subject(:client) { described_class.new(host, secure:) }

  let(:secure) { true }
  let(:host) { 'example.com:443' }
  let(:auth_token) { '12345' }
  let(:stub) { instance_double(SDGRPC::Scanner::Stub) }

  let(:payloads) { [SDGRPC::ScanRequest::Payload.new(id: '1', data: 'dummy')] }
  let(:request) { SDGRPC::ScanRequest.new(payloads:) }
  let(:requests) { [request, request] }

  let(:stub_scan_response) { SDGRPC::ScanResponse.new(status: GRPCStatus::STATUS_NOT_FOUND) }
  let(:stub_scan_stream_response) do
    [
      SDGRPC::ScanResponse.new(
        status: GRPCStatus::STATUS_NOT_FOUND,
        results: []
      ),
      SDGRPC::ScanResponse.new(
        status: GRPCStatus::STATUS_NOT_FOUND,
        results: []
      )
    ].to_enum
  end

  let(:metadata) { { "x-sd-auth" => auth_token } }

  before do
    allow(SDGRPC::Scanner::Stub).to receive(:new).and_return(stub)
    allow(stub).to receive_messages(scan: stub_scan_response, scan_stream: stub_scan_stream_response)
  end

  describe "#run_scan" do
    it "sends correct metadata and deadline" do
      before_test_time = Time.now
      client.run_scan(request:, auth_token:)

      expect(stub).to have_received(:scan).with(
        request,
        deadline: satisfy do |deadline|
          diff = (deadline - before_test_time)
          (diff - described_class::REQUEST_TIMEOUT_SECONDS) < 1 # considering buffer of 1 sec
        end,
        metadata: { 'x-sd-auth' => '12345' }
      )
    end

    it "transforms SD service response to SD response" do
      result = client.run_scan(request:, auth_token:)

      expect(result).to be_instance_of(SD::Response)
      expect(result.status).to eq(stub_scan_response.status)
      expect(result.results).to eq(stub_scan_response.results)
    end

    context "when an error occurs in the service" do
      it "returns SD response instead of raising error" do
        allow(stub).to receive(:scan).and_raise(GRPC::Unauthenticated)
        result = nil
        expect { result = client.run_scan(request:, auth_token:) }.not_to raise_error
        expect(result).to be_instance_of(SD::Response)
      end

      it "returns SD response with corresponding Status" do
        [
          [GRPC::InvalidArgument, SD::Status::INPUT_ERROR],
          [GRPC::Unauthenticated, SD::Status::AUTH_ERROR],
          [GRPC::Unknown, SD::Status::SCAN_ERROR],
          [GRPC::BadStatus, SD::Status::SCAN_ERROR]
        ].each do |grpc_error, sd_core_status|
          allow(stub).to receive(:scan).and_raise(grpc_error, "")

          result = nil
          expect { result = client.run_scan(request:, auth_token:) }.not_to raise_error

          expect(result).to be_instance_of(SD::Response)
          expect(result&.status).to eq(sd_core_status)
        end
      end
    end
  end

  describe "#run_scan_stream" do
    it "sends correct metadata and deadline" do
      before_test_time = Time.now
      client.run_scan_stream(requests:, auth_token:)

      expect(stub).to have_received(:scan_stream).with(
        requests,
        deadline: satisfy do |deadline|
          diff = (deadline - before_test_time)
          (diff - described_class::REQUEST_TIMEOUT_SECONDS) < 1 # considering buffer of 1 sec
        end,
        metadata: { 'x-sd-auth' => '12345' }
      )
    end

    it "transforms each streamed response to SD response" do
      result = client.run_scan_stream(requests:, auth_token:)

      expect(result).to be_instance_of(Array)
      expect(result.length).to eq(requests.length)
      result.each do |msg|
        expect(msg).to be_instance_of(SD::Response)
        expect(msg.status).to eq(SD::Status::NOT_FOUND)
      end
    end
  end
end
