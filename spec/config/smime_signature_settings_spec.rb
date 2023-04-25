# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SmimeSignatureSettings, feature_category: :shared do
  describe '.parse' do
    let(:default_smime_key) { Rails.root.join('.gitlab_smime_key') }
    let(:default_smime_cert) { Rails.root.join('.gitlab_smime_cert') }
    let(:default_smime_ca_certs) { nil }

    it 'sets correct default values to disabled' do
      parsed_settings = described_class.parse(nil)

      expect(parsed_settings['enabled']).to be(false)
      expect(parsed_settings['key_file']).to eq(default_smime_key)
      expect(parsed_settings['cert_file']).to eq(default_smime_cert)
      expect(parsed_settings['ca_certs_file']).to eq(default_smime_ca_certs)
    end

    context 'when providing custom values' do
      it 'sets correct default values to disabled' do
        custom_settings = GitlabSettings::Options.build({})

        parsed_settings = described_class.parse(custom_settings)

        expect(parsed_settings['enabled']).to be(false)
        expect(parsed_settings['key_file']).to eq(default_smime_key)
        expect(parsed_settings['cert_file']).to eq(default_smime_cert)
        expect(parsed_settings['ca_certs_file']).to eq(default_smime_ca_certs)
      end

      it 'enables smime with default key and cert' do
        custom_settings = GitlabSettings::Options.build({
          'enabled' => true
        })

        parsed_settings = described_class.parse(custom_settings)

        expect(parsed_settings['enabled']).to be(true)
        expect(parsed_settings['key_file']).to eq(default_smime_key)
        expect(parsed_settings['cert_file']).to eq(default_smime_cert)
        expect(parsed_settings['ca_certs_file']).to eq(default_smime_ca_certs)
      end

      it 'enables smime with custom key and cert' do
        custom_key = '/custom/key'
        custom_cert = '/custom/cert'
        custom_ca_certs = '/custom/ca_certs'
        custom_settings = GitlabSettings::Options.build({
          'enabled' => true,
          'key_file' => custom_key,
          'cert_file' => custom_cert,
          'ca_certs_file' => custom_ca_certs
        })

        parsed_settings = described_class.parse(custom_settings)

        expect(parsed_settings['enabled']).to be(true)
        expect(parsed_settings['key_file']).to eq(custom_key)
        expect(parsed_settings['cert_file']).to eq(custom_cert)
        expect(parsed_settings['ca_certs_file']).to eq(custom_ca_certs)
      end
    end
  end
end
