# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HTTP_V2::UrlAllowlist do
  let(:allowlist) { [] }

  describe '#domain_allowed?' do
    let(:allowlist) { %w[www.example.com example.com] }

    it 'returns true if domains present in allowlist' do
      not_allowed = %w[subdomain.example.com example.org]

      aggregate_failures do
        allowlist.each do |domain|
          expect(described_class).to be_domain_allowed(domain, allowlist)
        end

        not_allowed.each do |domain|
          expect(described_class).not_to be_domain_allowed(domain, allowlist)
        end
      end
    end

    it 'returns false when domain is blank' do
      expect(described_class).not_to be_domain_allowed(nil, allowlist)
    end

    context 'with ports' do
      let(:allowlist) { ['example.io:3000'] }

      it 'returns true if domain and ports present in allowlist' do
        parsed_allowlist = [['example.io', 3000]]
        not_allowed = [
          'example.io',
          ['example.io', 3001]
        ]

        aggregate_failures do
          parsed_allowlist.each do |domain, port|
            expect(described_class).to be_domain_allowed(domain, allowlist, port: port)
          end

          not_allowed.each do |domain, port|
            expect(described_class).not_to be_domain_allowed(domain, allowlist, port: port)
          end
        end
      end
    end
  end

  describe '#ip_allowed?' do
    let(:allowlist) do
      [
        '0.0.0.0',
        '127.0.0.1',
        '192.168.1.1',
        '0:0:0:0:0:ffff:192.168.1.2',
        '::ffff:c0a8:102',
        'fc00:bf8b:e62c:abcd:abcd:aaaa:aaaa:aaaa',
        '0:0:0:0:0:ffff:169.254.169.254',
        '::ffff:a9fe:a9fe',
        '::ffff:a9fe:a864',
        'fe80::c800:eff:fe74:8'
      ]
    end

    it 'returns true if ips present in allowlist' do
      aggregate_failures do
        allowlist.each do |ip_address|
          expect(described_class).to be_ip_allowed(ip_address, allowlist)
        end

        %w[172.16.2.2 127.0.0.2 fe80::c800:eff:fe74:9].each do |ip_address|
          expect(described_class).not_to be_ip_allowed(ip_address, allowlist)
        end
      end
    end

    it 'returns false when ip is blank' do
      expect(described_class).not_to be_ip_allowed(nil, allowlist)
    end

    context 'with ip ranges in allowlist' do
      let(:ipv4_range) { '127.0.0.0/28' }
      let(:ipv6_range) { 'fd84:6d02:f6d8:c89e::/124' }

      let(:allowlist) do
        [
          ipv4_range,
          ipv6_range
        ]
      end

      it 'does not allowlist ipv4 range when not in allowlist' do
        IPAddr.new(ipv4_range).to_range.to_a.each do |ip|
          expect(described_class).not_to be_ip_allowed(ip.to_s, [])
        end
      end

      it 'allowlists all ipv4s in the range when in allowlist' do
        IPAddr.new(ipv4_range).to_range.to_a.each do |ip|
          expect(described_class).to be_ip_allowed(ip.to_s, allowlist)
        end
      end

      it 'does not allowlist ipv6 range when not in allowlist' do
        IPAddr.new(ipv6_range).to_range.to_a.each do |ip|
          expect(described_class).not_to be_ip_allowed(ip.to_s, [])
        end
      end

      it 'allowlists all ipv6s in the range when in allowlist' do
        IPAddr.new(ipv6_range).to_range.to_a.each do |ip|
          expect(described_class).to be_ip_allowed(ip.to_s, allowlist)
        end
      end

      it 'does not allowlist IPs outside the range' do
        expect(described_class).not_to be_ip_allowed("fd84:6d02:f6d8:c89e:0:0:1:f", allowlist)

        expect(described_class).not_to be_ip_allowed("127.0.1.15", allowlist)
      end
    end

    context 'with ports' do
      let(:allowlist) { %w[127.0.0.9:3000 [2001:db8:85a3:8d3:1319:8a2e:370:7348]:443] }

      it 'returns true if ip and ports present in allowlist' do
        parsed_allowlist = [
          ['127.0.0.9', 3000],
          ['[2001:db8:85a3:8d3:1319:8a2e:370:7348]', 443]
        ]
        not_allowed = [
          '127.0.0.9',
          ['127.0.0.9', 3001],
          '[2001:db8:85a3:8d3:1319:8a2e:370:7348]',
          ['[2001:db8:85a3:8d3:1319:8a2e:370:7348]', 3001]
        ]

        aggregate_failures do
          parsed_allowlist.each do |ip, port|
            expect(described_class).to be_ip_allowed(ip, allowlist, port: port)
          end

          not_allowed.each do |ip, port|
            expect(described_class).not_to be_ip_allowed(ip, allowlist, port: port)
          end
        end
      end
    end
  end
end
