# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Settings do
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

  describe '.attr_encrypted_db_key_base_truncated' do
    it 'is a string with maximum 32 bytes size' do
      expect(described_class.attr_encrypted_db_key_base_truncated.bytesize)
        .to be <= 32
    end
  end

  describe '.attr_encrypted_db_key_base_12' do
    context 'when db key base secret is less than 12 bytes' do
      before do
        allow(described_class)
          .to receive(:attr_encrypted_db_key_base)
          .and_return('a' * 10)
      end

      it 'expands db key base secret to 12 bytes' do
        expect(described_class.attr_encrypted_db_key_base_12)
          .to eq(('a' * 10) + ('0' * 2))
      end
    end

    context 'when key has multiple multi-byte UTF chars exceeding 12 bytes' do
      before do
        allow(described_class)
          .to receive(:attr_encrypted_db_key_base)
          .and_return('❤' * 18)
      end

      it 'does not use more than 32 bytes' do
        db_key_base = described_class.attr_encrypted_db_key_base_12

        expect(db_key_base).to eq('❤' * 4)
        expect(db_key_base.bytesize).to eq 12
      end
    end
  end

  describe '.attr_encrypted_db_key_base_32' do
    context 'when db key base secret is less than 32 bytes' do
      before do
        allow(described_class)
          .to receive(:attr_encrypted_db_key_base)
          .and_return('a' * 10)
      end

      it 'expands db key base secret to 32 bytes' do
        expanded_key_base = ('a' * 10) + ('0' * 22)

        expect(expanded_key_base.bytesize).to eq 32
        expect(described_class.attr_encrypted_db_key_base_32)
          .to eq expanded_key_base
      end
    end

    context 'when db key base secret is 32 bytes' do
      before do
        allow(described_class)
          .to receive(:attr_encrypted_db_key_base)
          .and_return('a' * 32)
      end

      it 'returns original value' do
        expect(described_class.attr_encrypted_db_key_base_32)
          .to eq 'a' * 32
      end
    end

    context 'when db key base contains multi-byte UTF character' do
      before do
        allow(described_class)
          .to receive(:attr_encrypted_db_key_base)
          .and_return('❤' * 6)
      end

      it 'does not use more than 32 bytes' do
        db_key_base = described_class.attr_encrypted_db_key_base_32

        expect(db_key_base).to eq '❤❤❤❤❤❤' + ('0' * 14)
        expect(db_key_base.bytesize).to eq 32
      end
    end

    context 'when db key base multi-byte UTF chars exceeding 32 bytes' do
      before do
        allow(described_class)
          .to receive(:attr_encrypted_db_key_base)
          .and_return('❤' * 18)
      end

      it 'does not use more than 32 bytes' do
        db_key_base = described_class.attr_encrypted_db_key_base_32

        expect(db_key_base).to eq(('❤' * 10) + ('0' * 2))
        expect(db_key_base.bytesize).to eq 32
      end
    end
  end

  describe '.cron_for_service_ping' do
    it 'returns correct crontab for some manually calculated example' do
      allow(Gitlab::CurrentSettings)
        .to receive(:uuid) { 'd9e2f4e8-db1f-4e51-b03d-f427e1965c4a'}

      expect(described_class.send(:cron_for_service_ping)).to eq('21 18 * * 4')
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
      allow(Gitlab::Application.secrets).to receive(:encryped_settings_key_base).and_return(SecureRandom.hex(64))
    end

    it 'defaults to using the encrypted_settings_key_base for the key' do
      expect(Gitlab::EncryptedConfiguration).to receive(:new).with(hash_including(base_key: Gitlab::Application.secrets.encrypted_settings_key_base))
      Settings.encrypted('tmp/tests/test.enc')
    end

    it 'returns empty encrypted config when a key has not been set' do
      allow(Gitlab::Application.secrets).to receive(:encrypted_settings_key_base).and_return(nil)
      expect(Settings.encrypted('tmp/tests/test.enc').read).to be_empty
    end
  end
end
