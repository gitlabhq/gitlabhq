# frozen_string_literal: true

require 'spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::HTTP_V2::UrlBlocker, :stub_invalid_dns_only, feature_category: :shared do
  let(:schemes) { %w[http https] }

  # This test ensures backward compatibliity for the validate! method.
  # We shoud refactor all callers of validate! to handle a Result object:
  # https://gitlab.com/gitlab-org/gitlab/-/issues/410890
  describe '#validate!' do
    let(:options) { { schemes: schemes } }

    subject { described_class.validate!(import_url, **options) }

    shared_examples 'validates URI and hostname' do
      it 'runs the url validations' do
        uri, hostname = subject

        expect(uri).to eq(Addressable::URI.parse(expected_uri))
        expect(hostname).to eq(expected_hostname)
      end
    end

    context 'when the URL hostname is a domain' do
      context 'when domain can be resolved' do
        let(:import_url) { 'https://example.org' }

        before do
          stub_dns(import_url, ip_address: '93.184.216.34')
        end

        it_behaves_like 'validates URI and hostname' do
          let(:expected_uri) { 'https://93.184.216.34' }
          let(:expected_hostname) { 'example.org' }
          let(:expected_use_proxy) { false }
        end
      end
    end

    context 'when one flag requring IP validation is enabled' do
      using RSpec::Parameterized::TableSyntax

      let(:import_url) { 'https://localhost' }

      where(:deny_all_requests_except_allowed, :dns_rebind_protection, :allow_local_network, :allow_localhost) do
        true | false | true | true
        false | true | true | true
        false | false | false | true
        false | false | true | false
      end

      with_them do
        let(:options) do
          {
            deny_all_requests_except_allowed: deny_all_requests_except_allowed,
            dns_rebind_protection: dns_rebind_protection,
            allow_local_network: allow_local_network,
            allow_localhost: allow_localhost,
            schemes: schemes
          }
        end

        it 'attempts to validate IP' do
          expect(described_class).to receive(:validate_resolved_uri).and_return(
            described_class::Result.new(import_url, 'localhost', false))

          subject
        end
      end
    end

    context 'when all forms of IP validation are disabled' do
      let(:options) do
        {
          deny_all_requests_except_allowed: false,
          dns_rebind_protection: false,
          allow_local_network: true,
          allow_localhost: true,
          schemes: schemes
        }
      end

      let(:import_url) { 'https://localhost' }
      let(:expected_uri) { 'https://localhost' }
      let(:expected_hostname) { nil }
      let(:expected_use_proxy) { false }

      it 'does not attempt to resolve IPs' do
        expect(Addrinfo).not_to receive(:getaddrinfo)

        uri, hostname = subject

        expect(uri).to eq(Addressable::URI.parse(expected_uri))
        expect(hostname).to eq(expected_hostname)
      end
    end
  end

  describe '#validate_url_with_proxy!' do
    let(:options) { { schemes: schemes } }

    subject { described_class.validate_url_with_proxy!(import_url, **options) }

    shared_examples 'validates URI and hostname' do
      it 'runs the url validations' do
        expect(subject.uri).to eq(Addressable::URI.parse(expected_uri))
        expect(subject.hostname).to eq(expected_hostname)
        expect(subject.use_proxy).to eq(expected_use_proxy)
      end
    end

    shared_context 'when instance configured to deny all requests' do
      let(:options) { super().merge(deny_all_requests_except_allowed: true) }
    end

    shared_examples 'a URI denied by `deny_all_requests_except_allowed`' do
      context 'when instance setting is enabled' do
        include_context 'when instance configured to deny all requests'

        it 'blocks the request' do
          expect { subject }.to raise_error(described_class::BlockedUrlError)
        end
      end

      context 'when instance setting is not enabled' do
        it 'does not block the request' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when passed as an argument' do
        let(:options) { super().merge(deny_all_requests_except_allowed: arg_value) }

        context 'when argument is a proc that evaluates to true' do
          let(:arg_value) { proc { true } }

          it 'blocks the request' do
            expect { subject }.to raise_error(described_class::BlockedUrlError)
          end
        end

        context 'when argument is a proc that evaluates to false' do
          let(:arg_value) { proc { false } }

          it 'does not block the request' do
            expect { subject }.not_to raise_error
          end
        end

        context 'when argument is true' do
          let(:arg_value) { true }

          it 'blocks the request' do
            expect { subject }.to raise_error(described_class::BlockedUrlError)
          end
        end

        context 'when argument is false' do
          let(:arg_value) { false }

          it 'does not block the request' do
            expect { subject }.not_to raise_error
          end
        end
      end
    end

    shared_examples 'a URI exempt from `deny_all_requests_except_allowed`' do
      include_context 'when instance configured to deny all requests'

      it 'does not block the request' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when URI is nil' do
      let(:import_url) { nil }

      it_behaves_like 'validates URI and hostname' do
        let(:expected_uri) { nil }
        let(:expected_hostname) { nil }
        let(:expected_use_proxy) { true }
      end

      it_behaves_like 'a URI exempt from `deny_all_requests_except_allowed`'
    end

    context 'when URI is internal' do
      let(:import_url) { 'http://localhost' }

      before do
        stub_dns(import_url, ip_address: '127.0.0.1')
      end

      it_behaves_like 'validates URI and hostname' do
        let(:expected_uri) { 'http://127.0.0.1' }
        let(:expected_hostname) { 'localhost' }
        let(:expected_use_proxy) { false }
      end

      it_behaves_like 'a URI exempt from `deny_all_requests_except_allowed`'
    end

    context 'when URI is for a local object storage' do
      let(:import_url) { "#{host}/external-diffs/merge_request_diffs/mr-1/diff-1" }

      context 'when extra_allowed_uris is passed' do
        let(:options) { super().merge(extra_allowed_uris: [URI(host)]) }

        context 'with a local domain name' do
          let(:host) { 'http://review-minio-svc.svc:9000' }

          before do
            stub_dns(host, ip_address: '127.0.0.1')
          end

          it_behaves_like 'validates URI and hostname' do
            let(:expected_uri) { 'http://127.0.0.1:9000/external-diffs/merge_request_diffs/mr-1/diff-1' }
            let(:expected_hostname) { 'review-minio-svc.svc' }
            let(:expected_use_proxy) { false }
          end

          it_behaves_like 'a URI exempt from `deny_all_requests_except_allowed`'
        end

        context 'with an IP address' do
          let(:host) { 'http://127.0.0.1:9000' }

          it_behaves_like 'validates URI and hostname' do
            let(:expected_uri) { 'http://127.0.0.1:9000/external-diffs/merge_request_diffs/mr-1/diff-1' }
            let(:expected_hostname) { nil }
            let(:expected_use_proxy) { false }
          end

          it_behaves_like 'a URI exempt from `deny_all_requests_except_allowed`'
        end

        context 'with an LFS object storage' do
          let(:host) { 'http://127.0.0.1:9000' }

          context 'when extra_allowed_uris is not passed' do
            let(:options) { super().merge(extra_allowed_uris: []) }

            it 'raises an error' do
              expect { subject }.to raise_error(described_class::BlockedUrlError)
            end
          end
        end
      end

      context 'when extra_allowed_uris is not passed' do
        context 'with a local domain name' do
          let(:host) { 'http://review-minio-svc.svc:9000' }

          before do
            stub_dns(host, ip_address: '127.0.0.1')
          end

          it 'raises an error' do
            expect { subject }.to raise_error(described_class::BlockedUrlError)
          end
        end

        context 'with an IP address' do
          let(:host) { 'http://127.0.0.1:9000' }

          it 'raises an error' do
            expect { subject }.to raise_error(described_class::BlockedUrlError)
          end
        end
      end
    end

    context 'when resolving runs into a timeout' do
      let(:import_url) { 'http://example.com' }

      before do
        stub_const("#{described_class}::GETADDRINFO_TIMEOUT_SECONDS", 1)
        allow(Addrinfo).to receive(:getaddrinfo) { sleep 2 }
      end

      it 'raises an error due to DNS timeout' do
        expect { subject }.to raise_error(Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError, "execution expired")
      end
    end

    context 'when the URL hostname is a domain' do
      context 'when domain can be resolved' do
        let(:import_url) { 'https://example.org' }

        before do
          stub_dns(import_url, ip_address: '93.184.216.34')
        end

        it_behaves_like 'validates URI and hostname' do
          let(:expected_uri) { 'https://93.184.216.34' }
          let(:expected_hostname) { 'example.org' }
          let(:expected_use_proxy) { false }
        end

        it_behaves_like 'a URI denied by `deny_all_requests_except_allowed`'
      end

      context 'when domain cannot be resolved' do
        let(:import_url) { 'http://foobar.x' }

        it 'raises an error' do
          expect { subject }.to raise_error(described_class::BlockedUrlError)
        end

        context 'with HTTP_PROXY' do
          let(:import_url) { 'http://foobar.x' }

          before do
            stub_env('http_proxy', 'http://proxy.example.com')
          end

          it_behaves_like 'validates URI and hostname' do
            let(:expected_uri) { import_url }
            let(:expected_hostname) { nil }
            let(:expected_use_proxy) { true }
          end

          context 'with no_proxy' do
            before do
              stub_env('no_proxy', 'foobar.x')
            end

            it_behaves_like 'validates URI and hostname' do
              let(:expected_uri) { import_url }
              let(:expected_hostname) { nil }
              let(:expected_use_proxy) { false }
            end
          end
        end
      end

      context 'when domain is too long' do
        let(:import_url) { "https://example#{'a' * 1024}.com" }

        it 'raises an error' do
          expect { subject }.to raise_error(described_class::BlockedUrlError)
        end
      end
    end

    context 'when the URL hostname is an IP address' do
      let(:import_url) { 'https://93.184.216.34' }

      it_behaves_like 'validates URI and hostname' do
        let(:expected_uri) { import_url }
        let(:expected_hostname) { nil }
        let(:expected_use_proxy) { false }
      end

      it_behaves_like 'a URI denied by `deny_all_requests_except_allowed`'

      context 'when the address is invalid' do
        let(:import_url) { 'http://1.1.1.1.1' }

        it 'raises an error' do
          expect { subject }.to raise_error(described_class::BlockedUrlError)
        end
      end
    end

    context 'when DNS rebinding protection with IP allowed' do
      let(:import_url) { 'http://a.192.168.0.120.3times.127.0.0.1.1time.repeat.rebind.network:9121/scrape?target=unix:///var/opt/gitlab/redis/redis.socket&amp;check-keys=*' }

      before do
        stub_dns(import_url, ip_address: '192.168.0.120')

        allow(Gitlab::HTTP_V2::UrlAllowlist).to receive(:ip_allowed?).and_return(true)
      end

      it_behaves_like 'validates URI and hostname' do
        let(:expected_uri) { 'http://192.168.0.120:9121/scrape?target=unix:///var/opt/gitlab/redis/redis.socket&amp;check-keys=*' }
        let(:expected_hostname) { 'a.192.168.0.120.3times.127.0.0.1.1time.repeat.rebind.network' }
        let(:expected_use_proxy) { false }
      end

      it_behaves_like 'a URI exempt from `deny_all_requests_except_allowed`'

      context 'with HTTP_PROXY' do
        before do
          stub_env('http_proxy', 'http://proxy.example.com')
        end

        it_behaves_like 'validates URI and hostname' do
          let(:expected_uri) { import_url }
          let(:expected_hostname) { nil }
          let(:expected_use_proxy) { true }
        end

        context 'when domain is in no_proxy env' do
          before do
            stub_env('no_proxy', 'a.192.168.0.120.3times.127.0.0.1.1time.repeat.rebind.network')
          end

          it_behaves_like 'validates URI and hostname' do
            let(:expected_uri) { 'http://192.168.0.120:9121/scrape?target=unix:///var/opt/gitlab/redis/redis.socket&amp;check-keys=*' }
            let(:expected_hostname) { 'a.192.168.0.120.3times.127.0.0.1.1time.repeat.rebind.network' }
            let(:expected_use_proxy) { false }
          end
        end
      end
    end

    context 'with disabled DNS rebinding protection' do
      let(:options) { { dns_rebind_protection: false, schemes: schemes } }

      context 'when URI is internal' do
        let(:import_url) { 'http://localhost' }

        it_behaves_like 'validates URI and hostname' do
          let(:expected_uri) { import_url }
          let(:expected_hostname) { nil }
          let(:expected_use_proxy) { false }
        end

        it_behaves_like 'a URI exempt from `deny_all_requests_except_allowed`'
      end

      context 'when the URL hostname is a domain' do
        let(:import_url) { 'https://example.org' }

        context 'when domain can be resolved' do
          it_behaves_like 'validates URI and hostname' do
            let(:expected_uri) { import_url }
            let(:expected_hostname) { nil }
            let(:expected_use_proxy) { false }
          end

          it_behaves_like 'a URI denied by `deny_all_requests_except_allowed`'
        end

        context 'when domain cannot be resolved' do
          let(:import_url) { 'http://foobar.x' }

          it_behaves_like 'validates URI and hostname' do
            let(:expected_uri) { import_url }
            let(:expected_hostname) { nil }
            let(:expected_use_proxy) { false }
          end

          it_behaves_like 'a URI denied by `deny_all_requests_except_allowed`'
        end
      end

      context 'when the URL hostname is an IP address' do
        let(:import_url) { 'https://93.184.216.34' }

        it_behaves_like 'validates URI and hostname' do
          let(:expected_uri) { import_url }
          let(:expected_hostname) { nil }
          let(:expected_use_proxy) { false }
        end

        it_behaves_like 'a URI denied by `deny_all_requests_except_allowed`'

        context 'when it is invalid' do
          let(:import_url) { 'http://1.1.1.1.1' }

          it_behaves_like 'validates URI and hostname' do
            let(:expected_uri) { import_url }
            let(:expected_hostname) { nil }
            let(:expected_use_proxy) { false }
          end

          it_behaves_like 'a URI denied by `deny_all_requests_except_allowed`'
        end
      end
    end
  end

  describe '#blocked_url?' do
    let(:ports) { [80, 443] }

    it 'allows imports from configured web host and port' do
      import_url = "http://localhost:80/t.git"
      expect(described_class.blocked_url?(import_url, schemes: schemes)).to be false
    end

    it 'allows mirroring from configured SSH host and port' do
      import_url = "ssh://localhost:22/t.git"
      expect(described_class.blocked_url?(import_url, schemes: schemes)).to be false
    end

    it 'returns true for bad localhost hostname' do
      expect(described_class.blocked_url?('https://localhost:65535/foo/foo.git', schemes: schemes)).to be true
    end

    it 'returns true for bad port' do
      expect(described_class.blocked_url?('https://gitlab.com:25/foo/foo.git', ports: ports, schemes: schemes))
        .to be true
    end

    it 'returns true for bad scheme' do
      expect(described_class.blocked_url?('https://gitlab.com/foo/foo.git', schemes: ['https'])).to be false
      expect(described_class.blocked_url?('https://gitlab.com/foo/foo.git', schemes: ['http'])).to be true
    end

    it 'returns true for bad protocol on configured web/SSH host and ports' do
      web_url = "javascript://localhost:80/t.git%0aalert(1)"
      expect(described_class.blocked_url?(web_url, schemes: schemes)).to be true

      ssh_url = "javascript://localhost:22/t.git%0aalert(1)"
      expect(described_class.blocked_url?(ssh_url, schemes: schemes)).to be true
    end

    it 'returns true for localhost IPs' do
      expect(described_class.blocked_url?('https://[0:0:0:0:0:0:0:0]/foo/foo.git', schemes: schemes)).to be true
      expect(described_class.blocked_url?('https://0.0.0.0/foo/foo.git', schemes: schemes)).to be true
      expect(described_class.blocked_url?('https://[::]/foo/foo.git', schemes: schemes)).to be true
    end

    it 'returns true for loopback IP' do
      expect(described_class.blocked_url?('https://127.0.0.2/foo/foo.git', schemes: schemes)).to be true
      expect(described_class.blocked_url?('https://127.0.0.1/foo/foo.git', schemes: schemes)).to be true
      expect(described_class.blocked_url?('https://[::1]/foo/foo.git', schemes: schemes)).to be true
    end

    it 'returns true for alternative version of 127.0.0.1 (0177.1)' do
      expect(described_class.blocked_url?('https://0177.1:65535/foo/foo.git', schemes: schemes)).to be true
    end

    it 'returns true for alternative version of 127.0.0.1 (017700000001)' do
      expect(described_class.blocked_url?('https://017700000001:65535/foo/foo.git', schemes: schemes)).to be true
    end

    it 'returns true for alternative version of 127.0.0.1 (0x7f.1)' do
      expect(described_class.blocked_url?('https://0x7f.1:65535/foo/foo.git', schemes: schemes)).to be true
    end

    it 'returns true for alternative version of 127.0.0.1 (0x7f.0.0.1)' do
      expect(described_class.blocked_url?('https://0x7f.0.0.1:65535/foo/foo.git', schemes: schemes)).to be true
    end

    it 'returns true for alternative version of 127.0.0.1 (0x7f000001)' do
      expect(described_class.blocked_url?('https://0x7f000001:65535/foo/foo.git', schemes: schemes)).to be true
    end

    it 'returns true for alternative version of 127.0.0.1 (2130706433)' do
      expect(described_class.blocked_url?('https://2130706433:65535/foo/foo.git', schemes: schemes)).to be true
    end

    it 'returns true for alternative version of 127.0.0.1 (127.000.000.001)' do
      expect(described_class.blocked_url?('https://127.000.000.001:65535/foo/foo.git', schemes: schemes)).to be true
    end

    it 'returns true for alternative version of 127.0.0.1 (127.0.1)' do
      expect(described_class.blocked_url?('https://127.0.1:65535/foo/foo.git', schemes: schemes)).to be true
    end

    context 'with ipv6 mapped address' do
      it 'returns true for localhost IPs' do
        expect(described_class.blocked_url?('https://[0:0:0:0:0:ffff:0.0.0.0]/foo/foo.git', schemes: schemes))
          .to be true
        expect(described_class.blocked_url?('https://[::ffff:0.0.0.0]/foo/foo.git', schemes: schemes)).to be true
        expect(described_class.blocked_url?('https://[::ffff:0:0]/foo/foo.git', schemes: schemes)).to be true
      end

      it 'returns true for loopback IPs' do
        expect(described_class.blocked_url?('https://[0:0:0:0:0:ffff:127.0.0.1]/foo/foo.git', schemes: schemes))
          .to be true
        expect(described_class.blocked_url?('https://[::ffff:127.0.0.1]/foo/foo.git', schemes: schemes)).to be true
        expect(described_class.blocked_url?('https://[::ffff:7f00:1]/foo/foo.git', schemes: schemes)).to be true
        expect(described_class.blocked_url?('https://[0:0:0:0:0:ffff:127.0.0.2]/foo/foo.git', schemes: schemes))
          .to be true
        expect(described_class.blocked_url?('https://[::ffff:127.0.0.2]/foo/foo.git', schemes: schemes)).to be true
        expect(described_class.blocked_url?('https://[::ffff:7f00:2]/foo/foo.git', schemes: schemes)).to be true
      end
    end

    it 'returns true for a non-alphanumeric hostname' do
      aggregate_failures do
        expect(described_class).to be_blocked_url('ssh://-oProxyCommand=whoami/a', schemes: ['ssh'])

        # URI does allow non-ascii host names.
        expect(described_class).to be_blocked_url('ssh://ğitlab.com/a', schemes: ['ssh'])
      end
    end

    it 'returns true for invalid URL' do
      expect(described_class.blocked_url?('http://:8080', schemes: schemes)).to be true
    end

    it 'returns false for legitimate URL' do
      expect(described_class.blocked_url?('https://gitlab.com/foo/foo.git', schemes: schemes)).to be false
    end

    describe 'allow_local_network' do
      let(:shared_address_space_ips) { ['100.64.0.0', '100.64.127.127', '100.64.255.255'] }

      let(:local_ips) do
        [
          '192.168.1.2',
          '[0:0:0:0:0:ffff:192.168.1.2]',
          '[::ffff:c0a8:102]',
          '10.0.0.2',
          '[0:0:0:0:0:ffff:10.0.0.2]',
          '[::ffff:a00:2]',
          '172.16.0.2',
          '[0:0:0:0:0:ffff:172.16.0.2]',
          '[::ffff:ac10:20]',
          '[feef::1]',
          '[fee2::]',
          '[fc00:bf8b:e62c:abcd:abcd:aaaa:aaaa:aaaa]',
          *shared_address_space_ips
        ]
      end

      let(:limited_broadcast_address_variants) do
        [
          '255.255.255.255', # "normal"  dotted decimal
          '0377.0377.0377.0377', # Octal
          '0377.00000000377.00377.0000377', # Still octal
          '0xff.0xff.0xff.0xff', # hex
          '0xffffffff', # still hex
          '255.255.255.255:65535', # with a port
          '4294967295', # as an integer / dword
          '[::ffff:ffff:ffff]', # short IPv6
          '[0000:0000:0000:0000:0000:ffff:ffff:ffff]' # long IPv6
        ]
      end

      let(:fake_domain) { 'www.fakedomain.fake' }

      shared_examples 'allows local requests' do
        it 'does not block urls from private networks' do
          local_ips.each do |ip|
            stub_domain_resolv(fake_domain, ip) do
              expect(described_class).not_to be_blocked_url("http://#{fake_domain}", **url_blocker_attributes)
            end

            expect(described_class).not_to be_blocked_url("http://#{ip}", **url_blocker_attributes)
          end
        end

        it 'allows localhost endpoints' do
          expect(described_class).not_to be_blocked_url('http://0.0.0.0', **url_blocker_attributes)
          expect(described_class).not_to be_blocked_url('http://localhost', **url_blocker_attributes)
          expect(described_class).not_to be_blocked_url('http://127.0.0.1', **url_blocker_attributes)
        end

        it 'allows loopback endpoints' do
          expect(described_class).not_to be_blocked_url('http://127.0.0.2', **url_blocker_attributes)
        end

        it 'allows IPv4 link-local endpoints' do
          expect(described_class).not_to be_blocked_url('http://169.254.169.254', **url_blocker_attributes)
          expect(described_class).not_to be_blocked_url('http://169.254.168.100', **url_blocker_attributes)
        end

        it 'allows IPv6 link-local endpoints' do
          expect(described_class).not_to be_blocked_url(
            'http://[0:0:0:0:0:ffff:169.254.169.254]', **url_blocker_attributes)
          expect(described_class).not_to be_blocked_url('http://[::ffff:169.254.169.254]', **url_blocker_attributes)
          expect(described_class).not_to be_blocked_url('http://[::ffff:a9fe:a9fe]', **url_blocker_attributes)
          expect(described_class).not_to be_blocked_url(
            'http://[0:0:0:0:0:ffff:169.254.168.100]', **url_blocker_attributes)
          expect(described_class).not_to be_blocked_url('http://[::ffff:169.254.168.100]', **url_blocker_attributes)
          expect(described_class).not_to be_blocked_url('http://[::ffff:a9fe:a864]', **url_blocker_attributes)
          expect(described_class).not_to be_blocked_url('http://[fe80::c800:eff:fe74:8]', **url_blocker_attributes)
        end

        it 'allows limited broadcast address 255.255.255.255 and variants' do
          limited_broadcast_address_variants.each do |variant|
            expect(described_class).not_to be_blocked_url("https://#{variant}", **url_blocker_attributes),
              "Expected #{variant} to be allowed"
          end
        end
      end

      context 'when true (default)' do
        let(:url_blocker_attributes) do
          options.merge(
            allow_localhost: true,
            allow_local_network: true
          )
        end

        let(:options) { { schemes: schemes } }

        it_behaves_like 'allows local requests',
          { allow_localhost: true, allow_local_network: true, schemes: %w[http https] }
      end

      context 'when false' do
        it 'blocks urls from private networks' do
          local_ips.each do |ip|
            stub_domain_resolv(fake_domain, ip) do
              expect(described_class).to be_blocked_url(
                "http://#{fake_domain}", allow_local_network: false, schemes: schemes)
            end

            expect(described_class).to be_blocked_url("http://#{ip}", allow_local_network: false, schemes: schemes)
          end
        end

        it 'blocks IPv4 link-local endpoints' do
          expect(described_class).to be_blocked_url(
            'http://169.254.169.254', allow_local_network: false, schemes: schemes)
          expect(described_class).to be_blocked_url(
            'http://169.254.168.100', allow_local_network: false, schemes: schemes)
        end

        it 'blocks IPv6 link-local endpoints' do
          expect(described_class).to be_blocked_url(
            'http://[0:0:0:0:0:ffff:169.254.169.254]', allow_local_network: false, schemes: schemes)
          expect(described_class).to be_blocked_url(
            'http://[::ffff:169.254.169.254]', allow_local_network: false, schemes: schemes)
          expect(described_class).to be_blocked_url(
            'http://[::ffff:a9fe:a9fe]', allow_local_network: false, schemes: schemes)
          expect(described_class).to be_blocked_url(
            'http://[0:0:0:0:0:ffff:169.254.168.100]', allow_local_network: false, schemes: schemes)
          expect(described_class).to be_blocked_url(
            'http://[::ffff:169.254.168.100]', allow_local_network: false, schemes: schemes)
          expect(described_class).to be_blocked_url(
            'http://[::ffff:a9fe:a864]', allow_local_network: false, schemes: schemes)
          expect(described_class).to be_blocked_url(
            'http://[fe80::c800:eff:fe74:8]', allow_local_network: false, schemes: schemes)
        end

        it 'blocks limited broadcast address 255.255.255.255 and variants' do
          limited_broadcast_address_variants.each do |variant|
            expect(described_class).to be_blocked_url(
              "https://#{variant}", allow_local_network: false, schemes: schemes),
              "Expected #{variant} to be blocked"
          end
        end

        context 'when local domain/IP is allowed' do
          let(:url_blocker_attributes) do
            options.merge(
              allow_localhost: false,
              allow_local_network: false
            )
          end

          let(:options) { { schemes: schemes, outbound_local_requests_allowlist: allowlist } }

          context 'with IPs in allowlist' do
            let(:allowlist) do
              [
                '0.0.0.0',
                '127.0.0.1',
                '127.0.0.2',
                '192.168.1.1',
                *local_ips,
                '0:0:0:0:0:ffff:169.254.169.254',
                '::ffff:a9fe:a9fe',
                '::ffff:169.254.168.100',
                '::ffff:a9fe:a864',
                'fe80::c800:eff:fe74:8',
                '255.255.255.255',

                # garbage IPs
                '45645632345',
                'garbage456:more345gar:bage'
              ]
            end

            it_behaves_like 'allows local requests',
              { allow_localhost: false, allow_local_network: false, schemes: %w[http https] }

            it 'allows IP when dns_rebind_protection is disabled' do
              url = "http://example.com"
              attrs = url_blocker_attributes.merge(dns_rebind_protection: false)

              stub_domain_resolv('example.com', '192.168.1.2') do
                expect(described_class).not_to be_blocked_url(url, **attrs)
              end

              stub_domain_resolv('example.com', '192.168.1.3') do
                expect(described_class).to be_blocked_url(url, **attrs)
              end
            end

            it 'allows the limited broadcast address 255.255.255.255' do
              expect(described_class).not_to be_blocked_url('http://255.255.255.255', **url_blocker_attributes)
            end
          end

          context 'with domains in allowlist' do
            let(:allowlist) do
              [
                'www.example.com',
                'example.com',
                'xn--itlab-j1a.com',
                'garbage$^$%#$^&$'
              ]
            end

            it 'allows domains present in allowlist' do
              domain = 'example.com'
              subdomain1 = 'www.example.com'
              subdomain2 = 'subdomain.example.com'

              stub_domain_resolv(domain, '192.168.1.1') do
                expect(described_class).not_to be_blocked_url("http://#{domain}",
                  **url_blocker_attributes)
              end

              stub_domain_resolv(subdomain1, '192.168.1.1') do
                expect(described_class).not_to be_blocked_url("http://#{subdomain1}",
                  **url_blocker_attributes)
              end

              # subdomain2 is not part of the allowlist so it should be blocked
              stub_domain_resolv(subdomain2, '192.168.1.1') do
                expect(described_class).to be_blocked_url("http://#{subdomain2}",
                  **url_blocker_attributes)
              end
            end

            it 'works with unicode and idna encoded domains' do
              unicode_domain = 'ğitlab.com'
              idna_encoded_domain = 'xn--itlab-j1a.com'

              stub_domain_resolv(unicode_domain, '192.168.1.1') do
                expect(described_class).not_to be_blocked_url("http://#{unicode_domain}",
                  **url_blocker_attributes)
              end

              stub_domain_resolv(idna_encoded_domain, '192.168.1.1') do
                expect(described_class).not_to be_blocked_url("http://#{idna_encoded_domain}",
                  **url_blocker_attributes)
              end
            end

            shared_examples 'dns rebinding checks' do
              shared_examples 'allowlists the domain' do
                let(:allowlist) { [domain] }
                let(:url) { "http://#{domain}" }

                it do
                  expect(described_class).not_to be_blocked_url(url, **options, dns_rebind_protection: dns_rebind_value)
                end
              end

              describe 'dns_rebinding_setting' do
                context 'when enabled' do
                  let(:dns_rebind_value) { true }

                  it_behaves_like 'allowlists the domain'
                end

                context 'when disabled' do
                  let(:dns_rebind_value) { false }

                  it_behaves_like 'allowlists the domain'
                end
              end
            end

            context 'when the domain cannot be resolved' do
              let(:domain) { 'foobar.x' }

              it_behaves_like 'dns rebinding checks'
            end

            context 'when the domain can be resolved' do
              let(:domain) { 'example.com' }

              before do
                stub_dns(url, ip_address: '93.184.216.34')
              end

              it_behaves_like 'dns rebinding checks'
            end
          end

          context 'with ports' do
            let(:allowlist) do
              ["127.0.0.1:2000"]
            end

            it 'allows domain with port when resolved ip has port allowed' do
              stub_domain_resolv("www.resolve-domain.com", '127.0.0.1', 2000) do
                expect(described_class).not_to be_blocked_url(
                  "http://www.resolve-domain.com:2000", **url_blocker_attributes)
              end
            end
          end
        end
      end
    end

    describe 'enforce_user' do
      context 'when false (default)' do
        it 'does not block urls with a non-alphanumeric username' do
          expect(described_class).not_to be_blocked_url('ssh://-oProxyCommand=whoami@example.com/a', schemes: ['ssh'])

          # The leading character here is a Unicode "soft hyphen"
          expect(described_class).not_to be_blocked_url('ssh://­oProxyCommand=whoami@example.com/a', schemes: ['ssh'])

          # Unicode alphanumerics are allowed
          expect(described_class).not_to be_blocked_url('ssh://ğitlab@example.com/a', schemes: ['ssh'])
        end
      end

      context 'when true' do
        it 'blocks urls with a non-alphanumeric username' do
          aggregate_failures do
            expect(described_class).to be_blocked_url(
              'ssh://-oProxyCommand=whoami@example.com/a', enforce_user: true, schemes: ['ssh'])

            # The leading character here is a Unicode "soft hyphen"
            expect(described_class).to be_blocked_url(
              'ssh://­oProxyCommand=whoami@example.com/a', enforce_user: true, schemes: ['ssh'])

            # Unicode alphanumerics are allowed
            expect(described_class).not_to be_blocked_url(
              'ssh://ğitlab@example.com/a', enforce_user: true, schemes: ['ssh'])
          end
        end
      end
    end

    context 'when ascii_only is true' do
      it 'returns true for unicode domain' do
        expect(described_class.blocked_url?(
          'https://𝕘itⅼαƄ.com/foo/foo.bar', ascii_only: true, schemes: schemes)).to be true
      end

      it 'returns true for unicode tld' do
        expect(described_class.blocked_url?(
          'https://gitlab.ᴄοｍ/foo/foo.bar', ascii_only: true, schemes: schemes)).to be true
      end

      it 'returns true for unicode path' do
        expect(described_class.blocked_url?(
          'https://gitlab.com/𝒇οο/𝒇οο.Ƅαꮁ', ascii_only: true, schemes: schemes)).to be true
      end

      it 'returns true for IDNA deviations' do
        expect(described_class.blocked_url?(
          'https://mißile.com/foo/foo.bar', ascii_only: true, schemes: schemes)).to be true
        expect(described_class.blocked_url?(
          'https://miςςile.com/foo/foo.bar', ascii_only: true, schemes: schemes)).to be true
        expect(described_class.blocked_url?(
          'https://git‍lab.com/foo/foo.bar', ascii_only: true, schemes: schemes)).to be true
        expect(described_class.blocked_url?(
          'https://git‌lab.com/foo/foo.bar', ascii_only: true, schemes: schemes)).to be true
      end
    end

    it 'blocks urls with invalid ip address' do
      expect(described_class).to be_blocked_url('http://8.8.8.8.8', schemes: schemes)
    end

    it 'blocks urls whose hostname cannot be resolved' do
      expect(described_class).to be_blocked_url('http://foobar.x', schemes: schemes)
    end

    context 'when gitlab is running on a non-default port' do
      let(:gitlab_port) { 3000 }

      before do
        Gitlab::HTTP_V2.configuration.allowed_internal_uris = [
          URI::HTTP.build(
            scheme: 'http',
            host: 'gitlab.local',
            port: gitlab_port
          )
        ]
      end

      it 'returns true for url targeting the wrong port' do
        stub_domain_resolv('gitlab.local', '127.0.0.1') do
          expect(described_class).to be_blocked_url("http://gitlab.local/foo", schemes: schemes)
        end
      end

      it 'does not block url on gitlab port' do
        stub_domain_resolv('gitlab.local', '127.0.0.1', gitlab_port) do
          expect(described_class).not_to be_blocked_url("http://gitlab.local:#{gitlab_port}/foo", schemes: schemes)
        end
      end
    end

    def stub_domain_resolv(domain, ip, port = 80)
      address = instance_double(Addrinfo,
        ip_address: ip,
        ipv4_private?: true,
        ipv6_linklocal?: false,
        ipv4_loopback?: false,
        ipv6_loopback?: false,
        ipv4?: false,
        ip_port: port
      )
      allow(Addrinfo).to receive(:getaddrinfo).with(domain, port, any_args).and_return([address])
      allow(address).to receive(:ipv6_v4mapped?).and_return(false)

      yield

      allow(Addrinfo).to receive(:getaddrinfo).and_call_original
    end
  end

  describe '#validate_hostname' do
    let(:ip_addresses) do
      [
        '2001:db8:1f70::999:de8:7648:6e8',
        'FE80::C800:EFF:FE74:8',
        '::ffff:127.0.0.1',
        '::ffff:169.254.168.100',
        '::ffff:7f00:1',
        '0:0:0:0:0:ffff:0.0.0.0',
        'localhost',
        '127.0.0.1',
        '127.000.000.001',
        '0x7f000001',
        '0x7f.0.0.1',
        '0x7f.0.0.1',
        '017700000001',
        '0177.1',
        '2130706433',
        '::',
        '::1'
      ]
    end

    it 'does not raise error for valid Ip addresses' do
      ip_addresses.each do |ip|
        expect { described_class.send(:validate_hostname, ip) }.not_to raise_error
      end
    end
  end
end
