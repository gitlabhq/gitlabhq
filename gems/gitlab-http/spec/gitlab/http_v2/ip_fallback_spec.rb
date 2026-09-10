# frozen_string_literal: true

require 'spec_helper'
require 'webrick'

# Connecting to only the first resolved IP times out (surfacing as a Dependency Proxy
# 599) when that IP is unreachable, instead of trying the other resolved addresses.
RSpec.describe 'Gitlab::HTTP upstream IP fallback', feature_category: :shared do
  let(:reachable_ip) { '127.0.0.1' }
  # RFC 3849 documentation prefix; v6 first mirrors the dual-stack scenario the fallback targets.
  let(:unreachable_ip) { '2001:db8::1' }
  let(:hostname) { 'upstream.test' }

  let!(:server) do
    srv = WEBrick::HTTPServer.new(
      BindAddress: reachable_ip,
      Port: 0,
      Logger: WEBrick::Log.new('/dev/null'),
      AccessLog: []
    )
    srv.mount_proc('/') { |_req, res| res.body = 'ok' }
    Thread.new { srv.start }
    srv
  end

  let(:port) { server.config[:Port] }

  def get
    Gitlab::HTTP_V2.get(
      "http://#{hostname}:#{port}/",
      allow_local_requests: true,
      dns_rebinding_protection_enabled: true
    )
  end

  before do
    WebMock.allow_net_connect!

    # Unreachable IP resolves first, the dual-stack ordering that triggers the bug.
    allow(Addrinfo).to receive(:getaddrinfo).and_call_original
    allow(Addrinfo).to receive(:getaddrinfo)
      .with(hostname, port, anything, :STREAM, any_args)
      .and_return([Addrinfo.tcp(unreachable_ip, port), Addrinfo.tcp(reachable_ip, port)])

    # Fail the unreachable IP fast instead of waiting for a real connect timeout.
    allow(TCPSocket).to receive(:open).and_call_original
    allow(TCPSocket).to receive(:open)
      .with(unreachable_ip, anything, anything, anything)
      .and_raise(Net::OpenTimeout.new('execution expired'))
  end

  after do
    WebMock.disable_net_connect! # rubocop:disable RSpec/WebMockEnable -- method not available in gem
    server.shutdown
  end

  [
    Net::OpenTimeout, Errno::ETIMEDOUT, Errno::EHOSTUNREACH,
    Errno::ENETUNREACH, Errno::EADDRNOTAVAIL, Errno::EAFNOSUPPORT
  ].each do |error_class|
    context "when the first IP raises #{error_class}" do
      before do
        allow(TCPSocket).to receive(:open)
          .with(unreachable_ip, anything, anything, anything)
          .and_raise(error_class)
      end

      it 'falls back to the next resolved IP and completes the request' do
        response = get

        expect(response.code).to eq(200)
        expect(response.body).to eq('ok')
      end
    end
  end

  it 'raises when every resolved IP is unreachable' do
    allow(TCPSocket).to receive(:open)
      .with(reachable_ip, anything, anything, anything)
      .and_raise(Net::OpenTimeout.new('execution expired'))

    expect { get }.to raise_error(Net::OpenTimeout)
  end

  context 'when the connection is refused' do
    before do
      allow(TCPSocket).to receive(:open)
        .with(unreachable_ip, anything, anything, anything)
        .and_raise(Errno::ECONNREFUSED)
    end

    it 'surfaces the refused connection instead of falling back' do
      expect { get }.to raise_error(Errno::ECONNREFUSED)
    end

    it 'keeps the upstream "Failed to open TCP connection" message wrapper' do
      expect { get }.to raise_error(
        Errno::ECONNREFUSED,
        /Failed to open TCP connection to #{Regexp.escape(unreachable_ip)}:/
      )
    end
  end

  # Allowlisted hosts skip validation, so their co-resolved IPs must not be fallback targets.
  it 'does not fall back to a co-resolved IP that bypassed validation (SSRF)' do
    expect do
      Gitlab::HTTP_V2.get(
        "http://#{hostname}:#{port}/",
        extra_allowed_uris: [URI("http://#{hostname}:#{port}")],
        dns_rebinding_protection_enabled: true
      )
    end.to raise_error(Net::OpenTimeout)
  end
end
