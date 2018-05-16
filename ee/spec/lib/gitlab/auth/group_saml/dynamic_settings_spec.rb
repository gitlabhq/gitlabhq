require 'spec_helper'

describe Gitlab::Auth::GroupSaml::DynamicSettings do
  let(:saml_provider) { create(:saml_provider) }

  subject { described_class.new(saml_provider) }

  it 'behaves like an enumerator for settings' do
    expect(subject.to_h).to be_a(Hash)
  end

  it 'configures requests to transfrom redirect_to to RelayState' do
    expect(subject[:idp_sso_target_url_runtime_params]).to eq( redirect_to: :RelayState )
  end

  describe 'sets settings from saml_provider' do
    specify 'assertion_consumer_service_url' do
      expect(subject.keys).to include(:assertion_consumer_service_url)
    end

    specify 'issuer' do
      expect(subject.keys).to include(:issuer)
    end

    specify 'idp_cert_fingerprint' do
      expect(subject.keys).to include(:idp_cert_fingerprint)
    end

    specify 'idp_sso_target_url' do
      expect(subject.keys).to include(:idp_sso_target_url)
    end

    specify 'name_identifier_format' do
      expect(subject.keys).to include(:name_identifier_format)
    end
  end
end
