# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Settings, feature_category: :system_access do
  using RSpec::Parameterized::TableSyntax

  describe 'omniauth' do
    it 'defaults to enabled' do
      expect(described_class.omniauth.enabled).to be true
    end
  end

  describe '.load_dynamic_cron_schedules!' do
    it 'generates a valid cron schedule' do
      expect(Fugit::Cron.parse(described_class.load_dynamic_cron_schedules!)).to be_a(Fugit::Cron)
    end
  end

  describe 'cron_jobs job_class can be resolved' do
    it 'resolves all defined cron job worker classes' do
      Settings.cron_jobs.each_value do |job_config|
        next unless job_config

        job_class = job_config['job_class']

        next unless job_class

        expect(job_class.safe_constantize).not_to eq(nil), "The defined job class (#{job_class}) in the cron job settings cannot be resolved."
      end
    end
  end

  describe 'cron_jobs cron syntax is correct' do
    it 'all cron entries are correct' do
      Settings.cron_jobs.each_value do |job_config|
        next unless job_config

        job_class = job_config['job_class']
        cron = job_config['cron']

        next unless cron

        expect(Fugit.parse_cron(cron)).not_to eq(nil), "The defined cron schedule (within #{job_class}) is invalid: '#{cron}'."
      end
    end
  end

  describe '.build_ci_server_fqdn' do
    subject(:fqdn) { described_class.build_ci_server_fqdn }

    where(:host, :port, :relative_url, :result) do
      'acme.com' | 9090 | '/gitlab' | 'acme.com:9090/gitlab'
      'acme.com' | 443  | '/gitlab' | 'acme.com/gitlab'
      'acme.com' | 443  | ''        | 'acme.com'
      'acme.com' | 9090 | ''        | 'acme.com:9090'
      'test'     | 9090 | ''        | 'test:9090'
    end

    with_them do
      before do
        allow(Gitlab.config).to receive(:gitlab).and_return(
          GitlabSettings::Options.build({
            'host' => host,
            'https' => true,
            'port' => port,
            'relative_url_root' => relative_url
          }))
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '.attr_encrypted_db_key_base_truncated' do
    it 'returns the first item from #db_key_base_keys_truncated' do
      expect(described_class.attr_encrypted_db_key_base_truncated)
        .to eq(described_class.db_key_base_keys_truncated.first)
    end
  end

  describe '.db_key_base_keys_truncated' do
    it 'is an array of string with maximum 32 bytes size' do
      described_class.db_key_base_keys_truncated.each do |key|
        expect(key.bytesize).to be <= 32
      end
    end
  end

  describe '.attr_encrypted_db_key_base_32' do
    it 'returns the first item from #db_key_base_keys_32_bytes' do
      expect(described_class.attr_encrypted_db_key_base_32)
        .to eq(described_class.db_key_base_keys_32_bytes.first)
    end
  end

  describe '.db_key_base_keys_32_bytes' do
    context 'when db key base secret is less than 32 bytes' do
      before do
        allow(described_class)
          .to receive(:db_key_base_keys)
          .and_return(['a' * 10, '❤' * 6])
      end

      it 'expands db key base secret to 32 bytes' do
        expect(described_class.db_key_base_keys_32_bytes.first.bytesize).to eq(32)
        expect(described_class.db_key_base_keys_32_bytes.first).to eq(('a' * 10) + ('0' * 22))
        expect(described_class.db_key_base_keys_32_bytes.last.bytesize).to eq(32)
        expect(described_class.db_key_base_keys_32_bytes.last).to eq(('❤' * 6) + ('0' * 14))
      end
    end

    context 'when db key base secret is 32 bytes' do
      before do
        allow(described_class)
          .to receive(:db_key_base_keys)
          .and_return(['a' * 32, 'b' * 32])
      end

      it 'returns original value' do
        expect(described_class.db_key_base_keys_32_bytes.first.bytesize).to eq(32)
        expect(described_class.db_key_base_keys_32_bytes.first).to eq('a' * 32)
        expect(described_class.db_key_base_keys_32_bytes.last.bytesize).to eq(32)
        expect(described_class.db_key_base_keys_32_bytes.last).to eq('b' * 32)
      end
    end

    context 'when db key base contains multi-byte UTF character' do
      before do
        allow(described_class)
          .to receive(:db_key_base_keys)
          .and_return(['a' * 36, '❤' * 11])
      end

      it 'does not use more than 32 bytes' do
        expect(described_class.db_key_base_keys_32_bytes.first.bytesize).to eq(32)
        expect(described_class.db_key_base_keys_32_bytes.first).to eq('a' * 32)
        expect(described_class.db_key_base_keys_32_bytes.last.bytesize).to eq(32)
        expect(described_class.db_key_base_keys_32_bytes.last).to eq(('❤' * 10) + ('0' * 2))
      end
    end
  end

  describe '.attr_encrypted_db_key_base' do
    it 'returns the first item from #attr_encrypted_db_key_base' do
      expect(described_class.attr_encrypted_db_key_base)
        .to eq(described_class.db_key_base_keys.first)
    end
  end

  describe '.db_key_base_keys' do
    before do
      allow(Gitlab::Application.credentials)
        .to receive(:db_key_base)
        .and_return(raw_keys)
    end

    context 'when db key base secret is a string' do
      let(:raw_keys) { 'a' }

      it 'wraps the secret in an array' do
        expect(described_class.db_key_base_keys)
          .to eq(['a'])
      end
    end

    context 'when db key base secret is an array with a single element' do
      let(:raw_keys) { ['a'] }

      it 'returns the array' do
        expect(described_class.db_key_base_keys)
          .to eq(['a'])
      end
    end

    context 'when db key base secret is an array with several elements' do
      let(:raw_keys) { %w[a b] }

      it 'raises a MultipleDbKeyBaseError error' do
        expect { described_class.db_key_base_keys }
          .to raise_error(MultipleDbKeyBaseError, "Defining multiple `db_key_base` keys isn't supported yet.")
      end
    end
  end

  describe '.cron_for_service_ping' do
    it 'returns correct crontab for some manually calculated example' do
      allow(Gitlab::CurrentSettings)
        .to receive(:uuid) { 'd9e2f4e8-db1f-4e51-b03d-f427e1965c4a' }

      expect(described_class.send(:cron_for_service_ping)).to eq('44 10 * * 4')
    end

    it 'returns min, hour, day in the valid range' do
      allow(Gitlab::CurrentSettings)
        .to receive(:uuid) { SecureRandom.uuid }

      10.times do
        cron = described_class.send(:cron_for_service_ping).split(/\s/)

        expect(cron[0].to_i).to be_between(0, 59)
        expect(cron[1].to_i).to be_between(0, 23)
        expect(cron[4].to_i).to be_between(0, 6)
      end
    end
  end

  describe '.encrypted' do
    before do
      allow(Gitlab::Application.credentials).to receive(:encryped_settings_key_base).and_return(SecureRandom.hex(64))
    end

    it 'defaults to using the encrypted_settings_key_base for the key' do
      expect(Gitlab::EncryptedConfiguration).to receive(:new).with(hash_including(base_key: Gitlab::Application.credentials.encrypted_settings_key_base))
      described_class.encrypted('tmp/tests/test.enc')
    end

    it 'returns empty encrypted config when a key has not been set' do
      allow(Gitlab::Application.credentials).to receive(:encrypted_settings_key_base).and_return(nil)
      expect(described_class.encrypted('tmp/tests/test.enc').read).to be_empty
    end
  end

  describe '.microsoft_graph_mailer' do
    it 'defaults' do
      expect(described_class.microsoft_graph_mailer.enabled).to be false
      expect(described_class.microsoft_graph_mailer.user_id).to be_nil
      expect(described_class.microsoft_graph_mailer.tenant).to be_nil
      expect(described_class.microsoft_graph_mailer.client_id).to be_nil
      expect(described_class.microsoft_graph_mailer.client_secret).to be_nil
      expect(described_class.microsoft_graph_mailer.azure_ad_endpoint).to eq('https://login.microsoftonline.com')
      expect(described_class.microsoft_graph_mailer.graph_endpoint).to eq('https://graph.microsoft.com')
    end
  end

  describe '.repositories' do
    it 'sets up storage settings' do
      described_class.repositories.storages.each do |_, storage|
        expect(storage).to be_a Gitlab::GitalyClient::StorageSettings
      end
    end
  end

  describe '.build_sidekiq_routing_rules' do
    using RSpec::Parameterized::TableSyntax

    where(:input_rules, :result) do
      nil                         | [['*', 'default']]
      []                          | [['*', 'default']]
      [['name=foobar', 'foobar']] | [['name=foobar', 'foobar']]
    end

    with_them do
      it { expect(described_class.send(:build_sidekiq_routing_rules, input_rules)).to eq(result) }
    end
  end
end
