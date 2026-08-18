# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'cells/mailroom/config'

RSpec.describe Cells::Mailroom::Config do
  subject(:config) { described_class.new(rails_root: rails_root, rails_env: 'production') }

  let(:rails_root) { Dir.mktmpdir }

  let(:gitlab_yml) do
    <<~YAML
      production:
        gitlab:
          host: "gitlab.example.com"
        incoming_email:
          enabled: true
          address: "incoming+%{key}@example.com"
          user: "incoming@example.com"
          password: "secret"
          host: "imap.example.com"
          port: 993
          ssl: true
          mailbox: "inbox"
          idle_timeout: 60
          signing_key_file: "/etc/gitlab/incoming_email_signing_key.pem"
        service_desk_email:
          enabled: false
          address: "support+%{key}@example.com"
        cell:
          email_forwarding:
            scheme: http
          topology_service_client:
            address: "ts.example.com:443"
            metadata:
              key: value
    YAML
  end

  before do
    FileUtils.mkdir_p(File.join(rails_root, 'config'))
    File.write(File.join(rails_root, 'config', 'gitlab.yml'), gitlab_yml)

    # Resolve gitlab.yml from rails_root, ignoring any ambient config-file
    # override, without mutating the real ENV.
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with(described_class::CONFIG_FILE_ENV).and_return(nil)
  end

  after do
    FileUtils.remove_entry(rails_root)
  end

  describe '#mailboxes' do
    it 'builds mailbox attributes only for enabled mailboxes' do
      expect(config.mailboxes).to eq(
        [
          {
            email: 'incoming@example.com',
            password: 'secret',
            host: 'imap.example.com',
            port: 993,
            ssl: true,
            start_tls: nil,
            name: 'inbox',
            idle_timeout: 60,
            delivery_options: {
              mailbox_type: 'incoming_email',
              wildcard_address: 'incoming+%{key}@example.com'
            }
          }
        ]
      )
    end
  end

  describe '#cell_scheme' do
    it 'reads the configured scheme' do
      expect(config.cell_scheme).to eq('http')
    end

    context 'when not configured' do
      let(:gitlab_yml) { "production:\n  cell: {}\n" }

      it 'defaults to https' do
        expect(config.cell_scheme).to eq('https')
      end
    end
  end

  describe '#signing_key_path' do
    it 'reads the mailbox signing_key_file' do
      expect(config.signing_key_path('incoming_email')).to eq('/etc/gitlab/incoming_email_signing_key.pem')
    end

    context 'when no signing_key_file is configured' do
      let(:gitlab_yml) { "production:\n  incoming_email:\n    enabled: true\n" }

      it 'raises a MissingSecretError' do
        expect { config.signing_key_path('incoming_email') }
          .to raise_error(described_class::MissingSecretError)
      end
    end
  end

  describe '#topology_service_metadata' do
    it 'reads the configured metadata' do
      expect(config.topology_service_metadata).to eq('key' => 'value')
    end
  end

  describe '#gitlab_host' do
    it 'reads the configured GitLab host' do
      expect(config.gitlab_host).to eq('gitlab.example.com')
    end
  end

  describe '#route_unidentified_to_default_cell?' do
    it 'defaults to true when not configured' do
      expect(config.route_unidentified_to_default_cell?).to be(true)
    end

    context 'when explicitly disabled' do
      let(:gitlab_yml) do
        <<~YAML
          production:
            cell:
              email_forwarding:
                route_unidentified_to_default_cell: false
        YAML
      end

      it 'returns false' do
        expect(config.route_unidentified_to_default_cell?).to be(false)
      end
    end
  end

  describe '#arbitration_attributes' do
    context 'when no arbitration Redis is configured' do
      it 'falls back to noop arbitration' do
        expect(config.arbitration_attributes).to eq(arbitration_method: 'noop', arbitration_options: {})
      end
    end

    context 'when a redis_url is configured' do
      let(:gitlab_yml) do
        <<~YAML
          production:
            cell:
              email_forwarding:
                arbitration:
                  redis_url: "redis://redis.example.com:6379"
        YAML
      end

      it 'enables redis arbitration with the shared mailroom namespace' do
        expect(config.arbitration_attributes).to eq(
          arbitration_method: 'redis',
          arbitration_options: {
            redis_url: 'redis://redis.example.com:6379',
            namespace: described_class::ARBITRATION_NAMESPACE
          }
        )
      end

      it 'uses the same namespace as the existing GitLab mailroom' do
        expect(described_class::ARBITRATION_NAMESPACE).to eq('mail_room:gitlab')
      end
    end

    context 'when sentinels are configured' do
      let(:gitlab_yml) do
        <<~YAML
          production:
            cell:
              email_forwarding:
                arbitration:
                  sentinels:
                    - { host: "10.0.0.1", port: 26379 }
                  sentinel_password: "sentinel-secret"
                  redis_ssl_params: { verify_mode: "none" }
        YAML
      end

      it 'enables redis arbitration with the sentinel options' do
        expect(config.arbitration_attributes).to eq(
          arbitration_method: 'redis',
          arbitration_options: {
            redis_url: nil,
            namespace: described_class::ARBITRATION_NAMESPACE,
            redis_ssl_params: { 'verify_mode' => 'none' },
            sentinels: [{ 'host' => '10.0.0.1', 'port' => 26379 }],
            sentinel_password: 'sentinel-secret'
          }
        )
      end
    end
  end
end
