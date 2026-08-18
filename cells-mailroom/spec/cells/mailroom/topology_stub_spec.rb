# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'cells/mailroom/topology_stub'

RSpec.describe Cells::Mailroom::TopologyStub do
  describe '.credentials' do
    let(:tls_enabled) { true }
    let(:certs) { {} }

    let(:config) do
      instance_double(
        Cells::Mailroom::Config,
        topology_service_tls_enabled?: tls_enabled,
        topology_service_certs: certs
      )
    end

    subject(:credentials) { described_class.credentials(config) }

    context 'when TLS is disabled' do
      let(:tls_enabled) { false }

      it 'uses an insecure channel' do
        expect(credentials).to eq(:this_channel_is_insecure)
      end
    end

    context 'when TLS is enabled with readable key and certificate files' do
      let(:key_file) { Tempfile.create('key') }
      let(:cert_file) { Tempfile.create('cert') }
      let(:certs) do
        { 'private_key_file' => key_file.path, 'certificate_file' => cert_file.path }
      end

      before do
        key_file.write('key'); key_file.close
        cert_file.write('cert'); cert_file.close
      end

      after do
        [key_file.path, cert_file.path].each { |p| File.unlink(p) if File.exist?(p) }
      end

      it 'builds mutual TLS channel credentials' do
        expect(GRPC::Core::ChannelCredentials).to receive(:new).with(nil, 'key', 'cert')

        credentials
      end
    end

    context 'when TLS is enabled but no key or certificate is configured' do
      let(:certs) { {} }

      it 'raises rather than silently degrading to a non-mTLS channel' do
        expect { credentials }.to raise_error(described_class::CredentialsError, /not configured/)
      end
    end

    context 'when TLS is enabled but the configured files are missing' do
      let(:certs) do
        { 'private_key_file' => '/does/not/exist/key.pem', 'certificate_file' => '/does/not/exist/cert.pem' }
      end

      it 'raises rather than silently degrading to a non-mTLS channel' do
        expect { credentials }.to raise_error(described_class::CredentialsError, /not found/)
      end
    end
  end
end
