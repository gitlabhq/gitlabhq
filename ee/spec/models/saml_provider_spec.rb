require 'spec_helper'

describe SamlProvider do
  describe "Associations" do
    it { is_expected.to belong_to :group }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:sso_url) }
    it { is_expected.to validate_presence_of(:certificate_fingerprint) }

    it 'expects sso_url to be an https URL' do
      expect(subject).to allow_value('https://example.com').for(:sso_url)
      expect(subject).not_to allow_value('http://example.com').for(:sso_url)
    end

    it 'expects certificate_fingerprint to be in an accepted format' do
      expect(subject).to allow_value('000030EDC285E01D6B5EA33010A79ADD142F5004').for(:certificate_fingerprint)
      expect(subject).to allow_value('00:00:30:ED:C2:85:E0:1D:6B:5E:A3:30:10:A7:9A:DD:14:2F:50:04').for(:certificate_fingerprint)
      expect(subject).to allow_value('00-00-30-ED-C2-85-E0-1D-6B-5E-A3-30-10-A7-9A-DD-14-2F-50-04').for(:certificate_fingerprint)
      expect(subject).to allow_value('00 00 30 ED C2 85 E0 1D 6B 5E A3 30 10 A7 9A DD 14 2F 50 04').for(:certificate_fingerprint)
      sha512 = 'a12bc3d4567ef89ba97f4d1904815d56a497ffc2fe9d5b0f13439a5da73f4f1afde03b1c1b213128e173da24e75cadf224286696f5171540eedf59b684a5f8dd'
      expect(subject).to allow_value(sha512).for(:certificate_fingerprint)

      too_short = '00:00:30'
      invalid_characters = '00@0030EDC285E01D6B5EA33010A79ADD142F5004'
      expect(subject).not_to allow_value(too_short).for(:certificate_fingerprint)
      expect(subject).not_to allow_value(invalid_characters).for(:certificate_fingerprint)
    end

    it 'requires group to be top-level' do
      group = create(:group)
      nested_group = create(:group, :nested)

      expect(subject).to allow_value(group).for(:group)
      expect(subject).not_to allow_value(nested_group).for(:group)
    end
  end

  describe 'Default values' do
    subject(:saml_provider) { described_class.new }

    it 'defaults enabled to true' do
      expect(subject).to be_enabled
    end
  end

  describe '#settings' do
    let(:group) { create(:group, path: 'foo-group')}
    let(:settings) { subject.settings }

    subject(:saml_provider) { create(:saml_provider, group: group) }

    before do
      stub_config_setting(url: 'https://localhost')
    end

    it 'generates callback URL' do
      expect(settings[:assertion_consumer_service_url]).to eq "https://localhost/groups/foo-group/-/saml/callback"
    end

    it 'generates issuer from group' do
      expect(settings[:issuer]).to eq "https://localhost/groups/foo-group"
    end

    it 'includes NameID format' do
      expect(settings[:name_identifier_format]).to start_with 'urn:oasis:names:tc:'
    end

    it 'includes fingerprint' do
      expect(settings[:idp_cert_fingerprint]).to eq saml_provider.certificate_fingerprint
    end

    it 'includes SSO URL' do
      expect(settings[:idp_sso_target_url]).to eq saml_provider.sso_url
    end
  end
end
