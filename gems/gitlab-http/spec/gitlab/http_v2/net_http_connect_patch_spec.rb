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
    shared_examples 'scheme-aware proxy selection' do
      context 'when http_proxy and https_proxy have different ports' do
        before do
          stub_env('http_proxy', 'http://proxy.example.com:80')
          stub_env('https_proxy', 'http://proxy.example.com:443')
        end

        it 'uses https_proxy port for SSL connections', :aggregate_failures do
          http = Net::HTTP.new('example.com', 443)
          http.use_ssl = true

          expect(http.proxy?).to be true
          expect(http.proxy_address).to eq('proxy.example.com')
          expect(http.proxy_port).to eq(443)
        end

        it 'uses http_proxy port for non-SSL connections', :aggregate_failures do
          http = Net::HTTP.new('example.com', 80)

          expect(http.proxy?).to be true
          expect(http.proxy_address).to eq('proxy.example.com')
          expect(http.proxy_port).to eq(80)
        end
      end

      context 'when only https_proxy is set' do
        before do
          stub_env('https_proxy', 'http://proxy.example.com:8080')
          stub_env('http_proxy', nil)
          stub_env('HTTP_PROXY', nil)
        end

        it 'does not use a proxy for non-SSL connections' do
          http = Net::HTTP.new('example.com', 80)

          expect(http.proxy?).to be false
        end
      end

      context 'when only http_proxy is set' do
        before do
          stub_env('http_proxy', 'http://proxy.example.com:80')
          stub_env('https_proxy', nil)
          stub_env('HTTPS_PROXY', nil)
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

      context 'when only uppercase proxy variables are set' do
        before do
          stub_env('http_proxy', nil)
          stub_env('https_proxy', nil)
          stub_env('HTTPS_PROXY', 'http://proxy.example.com:443')
          stub_env('HTTP_PROXY', 'http://proxy.example.com:80')
        end

        it 'selects the proxy for each request scheme', :aggregate_failures do
          https = Net::HTTP.new('example.com', 443)
          https.use_ssl = true
          http = Net::HTTP.new('example.com', 80)

          expect(https.proxy_port).to eq(443)
          expect(http.proxy_port).to eq(80)
        end
      end

      context 'when the proxy value is empty' do
        before do
          stub_env('https_proxy', '')
        end

        it 'does not use a proxy' do
          http = Net::HTTP.new('example.com', 443)
          http.use_ssl = true

          expect(http.proxy?).to be false
        end
      end
    end

    context 'when GITLAB_PROXY_NO_DNS is not set (default behavior)' do
      before do
        stub_env('GITLAB_PROXY_NO_DNS', nil)
        stub_env('https_proxy', 'http://proxy.example.com:443')
        allow(IPSocket).to receive(:getaddress).and_return('203.0.113.1')
      end

      it_behaves_like 'scheme-aware proxy selection'

      it 'delegates to find_proxy, which resolves the destination hostname', :aggregate_failures do
        http = Net::HTTP.new('cloud.gitlab.com', 443)
        http.use_ssl = true

        expect(http.proxy?).to be true
        expect(http.proxy_address).to eq('proxy.example.com')
        expect(IPSocket).to have_received(:getaddress).with('cloud.gitlab.com')
      end

      context 'with a CIDR no_proxy entry and a hostname that resolves into the range' do
        before do
          stub_env('no_proxy', '10.0.0.0/8')
          allow(IPSocket).to receive(:getaddress).with('internal.corp').and_return('10.20.30.40')
        end

        it 'bypasses the proxy because the resolved IP falls inside the CIDR' do
          http = Net::HTTP.new('internal.corp', 443)
          http.use_ssl = true

          expect(http.proxy?).to be false
        end
      end
    end

    context 'when GITLAB_PROXY_NO_DNS=1 (opt-in no-DNS behavior)' do
      before do
        stub_env('GITLAB_PROXY_NO_DNS', '1')
        stub_env('https_proxy', 'http://proxy.example.com:443')
      end

      it_behaves_like 'scheme-aware proxy selection'

      context 'with REQUEST_METHOD set for an HTTP request #security' do
        before do
          stub_env('REQUEST_METHOD', 'GET')
          allow(ENV).to receive(:include?).with('REQUEST_METHOD').and_return(true)
          stub_env('http_proxy', nil)
          stub_env('HTTP_PROXY', 'http://attacker.invalid:3128')
          stub_env('CGI_HTTP_PROXY', nil)
        end

        it 'ignores HTTP_PROXY from a request header without a CGI fallback' do
          expect(Net::HTTP.new('example.com', 80).proxy?).to be false
        end

        it 'uses CGI_HTTP_PROXY when present', :aggregate_failures do
          stub_env('CGI_HTTP_PROXY', 'http://proxy.example.com:8080')

          http = Net::HTTP.new('example.com', 80)

          expect(http.proxy_address).to eq('proxy.example.com')
          expect(http.proxy_port).to eq(8080)
        end

        it 'prefers lowercase http_proxy to the CGI fallback', :aggregate_failures do
          stub_env('http_proxy', 'http://proxy.example.com:8080')
          stub_env('CGI_HTTP_PROXY', 'http://fallback.example.com:3128')

          http = Net::HTTP.new('example.com', 80)

          expect(http.proxy_address).to eq('proxy.example.com')
          expect(http.proxy_port).to eq(8080)
        end

        it 'does not use the CGI fallback when the lowercase proxy variable is empty' do
          stub_env('HTTP_PROXY', nil)
          stub_env('http_proxy', '')
          stub_env('CGI_HTTP_PROXY', 'http://fallback.example.com:3128')

          http = Net::HTTP.new('example.com', 80)

          expect(http.proxy?).to be false
        end
      end

      it 'never resolves the destination hostname to decide on the proxy', :aggregate_failures do
        expect(IPSocket).not_to receive(:getaddress)

        http = Net::HTTP.new('cloud.gitlab.com', 443)
        http.use_ssl = true

        expect(http.proxy?).to be true
        expect(http.proxy_address).to eq('proxy.example.com')
      end

      context 'with a domain-suffix no_proxy entry' do
        before do
          stub_env('no_proxy', '.internal.example.com')
        end

        it 'bypasses the proxy for matching hostnames without resolving DNS', :aggregate_failures do
          expect(IPSocket).not_to receive(:getaddress)

          http = Net::HTTP.new('service.internal.example.com', 443)
          http.use_ssl = true

          expect(http.proxy?).to be false
        end
      end

      context 'with a CIDR no_proxy entry' do
        before do
          stub_env('no_proxy', '10.0.0.0/8')
        end

        it 'matches a literal IP target within the range without resolving DNS', :aggregate_failures do
          expect(IPSocket).not_to receive(:getaddress)

          http = Net::HTTP.new('10.1.2.3', 443)
          http.use_ssl = true

          expect(http.proxy?).to be false
        end

        it 'proxies a hostname target rather than resolving it against the CIDR', :aggregate_failures do
          expect(IPSocket).not_to receive(:getaddress)

          http = Net::HTTP.new('cloud.gitlab.com', 443)
          http.use_ssl = true

          expect(http.proxy?).to be true
        end
      end

      context 'when the target is a loopback address' do
        shared_examples 'a loopback address' do |target|
          it "does not use a proxy for #{target}", :aggregate_failures do
            expect(IPSocket).not_to receive(:getaddress)

            http = Net::HTTP.new(target, 443)
            http.use_ssl = true

            expect(http.proxy?).to be false
          end
        end

        it_behaves_like 'a loopback address', '127.1'
        it_behaves_like 'a loopback address', '::1'
      end

      context 'when the target is a localhost hostname' do
        shared_examples 'a localhost name' do |host|
          it "does not proxy #{host}", :aggregate_failures do
            expect(IPSocket).not_to receive(:getaddress)

            http = Net::HTTP.new(host, 443)
            http.use_ssl = true

            expect(http.proxy?).to be false
          end
        end

        it_behaves_like 'a localhost name', 'localhost'
        it_behaves_like 'a localhost name', 'gdk.localhost'
        it_behaves_like 'a localhost name', 'LOCALHOST.'
      end

      it 'proxies a hostname that would resolve to loopback without looking it up', :aggregate_failures do
        allow(IPSocket).to receive(:getaddress).with('myalias.internal').and_return('127.0.0.1')

        http = Net::HTTP.new('myalias.internal', 443)
        http.use_ssl = true

        expect(http.proxy?).to be true
        expect(IPSocket).not_to have_received(:getaddress)
      end
    end
  end
end
