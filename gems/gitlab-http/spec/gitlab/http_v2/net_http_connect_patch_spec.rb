# frozen_string_literal: true

require 'spec_helper'
require 'webrick'
require 'webrick/https'

RSpec.describe 'Net::HTTP#connect DNS rebinding tests', feature_category: :shared do
  describe '#connect' do
    let(:host) { 'localhost' }
    let(:host_ip) { '127.0.0.1' }

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

  describe '#proxy_uri' do
    context 'when http_proxy and https_proxy have different ports' do
      before do
        stub_env('http_proxy', 'http://proxy.example.com:80')
        stub_env('https_proxy', 'http://proxy.example.com:443')
      end

      it 'uses https_proxy port for SSL connections' do
        http = Net::HTTP.new('example.com', 443)
        http.use_ssl = true

        expect(http.proxy?).to be true
        expect(http.proxy_address).to eq('proxy.example.com')
        expect(http.proxy_port).to eq(443)
      end

      it 'uses http_proxy port for non-SSL connections' do
        http = Net::HTTP.new('example.com', 80)

        expect(http.proxy?).to be true
        expect(http.proxy_address).to eq('proxy.example.com')
        expect(http.proxy_port).to eq(80)
      end
    end

    context 'when only https_proxy is set' do
      before do
        stub_env('https_proxy', 'http://proxy.example.com:8080')
      end

      it 'uses https_proxy for SSL connections' do
        http = Net::HTTP.new('example.com', 443)
        http.use_ssl = true

        expect(http.proxy?).to be true
        expect(http.proxy_port).to eq(8080)
      end

      it 'does not use a proxy for non-SSL connections' do
        http = Net::HTTP.new('example.com', 80)

        expect(http.proxy?).to be false
      end
    end

    context 'when only http_proxy is set' do
      before do
        stub_env('http_proxy', 'http://proxy.example.com:80')
      end

      it 'does not use http_proxy for SSL connections' do
        http = Net::HTTP.new('example.com', 443)
        http.use_ssl = true

        expect(http.proxy?).to be false
      end
    end

    context 'when no_proxy matches the target host' do
      before do
        stub_env('https_proxy', 'http://proxy.example.com:443')
        stub_env('no_proxy', 'example.com')
      end

      it 'does not use a proxy for the excluded host' do
        http = Net::HTTP.new('example.com', 443)
        http.use_ssl = true

        expect(http.proxy?).to be false
      end
    end
  end
end
