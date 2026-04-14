# frozen_string_literal: true

require 'spec_helper'
require 'webrick'
require 'webrick/https'

RSpec.describe 'Net::HTTP#connect DNS rebinding tests', feature_category: :shared do
  let(:host) { 'localhost' }
  let(:host_ip) { '127.0.0.1' }
  let(:rack_app) do
    proc do |_env|
      ['200', { 'Content-Type' => 'text/plain' }, ['Hello, world!']]
    end
  end

  let!(:http_server) do
    Class.new do
      attr_accessor :sni_hostname

      def initialize
        @server = WEBrick::HTTPServer.new(
          Port: 0,
          SSLEnable: true,
          SSLCertName: [%w[CN localhost]],
          SSLServerNameCallback: proc { |args| sni_callback(*args) },
          Logger: WEBrick::Log.new('/dev/null'),
          AccessLog: []
        )

        @server.mount_proc '/' do |_req, res|
          res.body = 'Hello, world!'
        end

        Thread.new { @server.start }
      end

      def port
        @server.config[:Port]
      end

      def shutdown
        @server.shutdown
      end

      def sni_callback(sslsocket, hostname = nil)
        @sni_hostname = hostname
        @server.ssl_servername_callback(sslsocket, hostname)
      end
    end.new
  end

  describe '#connect' do
    before do
      WebMock.allow_net_connect!
    end

    after do
      WebMock.disable_net_connect! # rubocop:disable RSpec/WebMockEnable -- method not available in gem
      http_server.shutdown
    end

    shared_examples 'GET request' do
      it 'makes a successful HTTPS connection' do
        http = Net::HTTP.new(http_host, http_server.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.hostname_override = hostname_override if hostname_override

        request = Net::HTTP::Get.new('/')

        response = http.start { http.request(request) }
        expect(response.code).to eq('200')
        expect(response.body).to include('Hello, world!')
        expect(http_server.sni_hostname).to eq(expected_sni)
      end
    end

    context 'with hostname' do
      let(:http_host) { host }
      let(:expected_sni) { host }
      let(:hostname_override) { nil }

      it_behaves_like 'GET request'
    end

    context 'with IP address' do
      let(:http_host) { host_ip }
      let(:expected_sni) { nil }
      let(:hostname_override) { nil }

      it_behaves_like 'GET request'
    end

    context 'with hostname override' do
      let(:http_host) { host_ip }
      let(:hostname_override) { host }
      let(:expected_sni) { host }

      it_behaves_like 'GET request'
    end

    context 'with IPv6 address', if: Socket.ip_address_list.any?(&:ipv6_loopback?) do
      let(:http_host) { '::1' }
      let(:expected_sni) { nil }
      let(:hostname_override) { nil }

      it_behaves_like 'GET request'
    end

    context 'with IPv6 address and hostname override', if: Socket.ip_address_list.any?(&:ipv6_loopback?) do
      let(:http_host) { '::1' }
      let(:hostname_override) { host }
      let(:expected_sni) { host }

      it_behaves_like 'GET request'
    end
  end

  describe 'CONNECT request format through proxy' do
    before do
      WebMock.allow_net_connect!(net_http_connect_on_start: true)
    end

    after do
      WebMock.disable_net_connect! # rubocop:disable RSpec/WebMockEnable -- method not available in gem
    end

    shared_examples 'proxy CONNECT request' do |target_host, expected_target|
      it "sends correct CONNECT request for #{target_host}" do
        fake_proxy = TCPServer.new('127.0.0.1', 0)
        proxy_port = fake_proxy.addr[1]
        connect_request = nil

        proxy_thread = Thread.new do
          client = fake_proxy.accept
          lines = []
          lines << client.gets until lines.last == "\r\n"
          connect_request = lines.join
          client.write("HTTP/1.1 400 Bad Request\r\n\r\n")
          client.close
        rescue StandardError
          # ignore errors from client disconnect
        ensure
          fake_proxy.close
        end

        http = Net::HTTP.new(target_host, 8080, '127.0.0.1', proxy_port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        begin
          http.start
        rescue StandardError
          nil
        end
        proxy_thread.join(2)

        expect(connect_request).to include("CONNECT #{expected_target}:8080")
        expect(connect_request).to include("Host: #{expected_target}:8080")
      end
    end

    it_behaves_like 'proxy CONNECT request', '2001:db8::1', '[2001:db8::1]'
    it_behaves_like 'proxy CONNECT request', '::1', '[::1]'
    it_behaves_like 'proxy CONNECT request', 'fe80::1', '[fe80::1]'
    it_behaves_like 'proxy CONNECT request', '127.0.0.1', '127.0.0.1'
    it_behaves_like 'proxy CONNECT request', 'example.com', 'example.com'
  end
end
