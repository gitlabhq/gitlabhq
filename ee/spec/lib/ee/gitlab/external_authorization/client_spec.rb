require 'spec_helper'

describe EE::Gitlab::ExternalAuthorization::Client do
  let(:user) { build(:user, email: 'dummy_user@example.com') }
  let(:dummy_url) { 'https://dummy.net/' }
  subject(:client) { described_class.new(user, 'dummy_label') }

  before do
    stub_application_setting(external_authorization_service_url: dummy_url)
  end

  describe '#request_access' do
    it 'performs requests to the configured endpoint' do
      expect(Excon).to receive(:post).with(dummy_url, any_args)

      client.request_access
    end

    it 'adds the correct params for the user to the body of the request' do
      expected_body = {
        user_identifier: 'dummy_user@example.com',
        project_classification_label: 'dummy_label'
      }.to_json
      expect(Excon).to receive(:post)
                         .with(dummy_url, hash_including(body: expected_body))

      client.request_access
    end

    it 'respects the the timeout' do
      stub_application_setting(
        external_authorization_service_timeout: 3
      )

      expect(Excon).to receive(:post).with(dummy_url,
                                           hash_including(
                                             connect_timeout: 3,
                                             read_timeout: 3,
                                             write_timeout: 3
                                           ))

      client.request_access
    end

    it 'adds the mutual tls params when they are present' do
      stub_application_setting(
        external_auth_client_cert: 'the certificate data',
        external_auth_client_key: 'the key data',
        external_auth_client_key_pass: 'open sesame'
      )
      expected_params = {
        client_cert_data: 'the certificate data',
        client_key_data: 'the key data',
        client_key_pass: 'open sesame'
      }

      expect(Excon).to receive(:post).with(dummy_url, hash_including(expected_params))

      client.request_access
    end

    it 'returns an expected response' do
      expect(Excon).to receive(:post)

      expect(client.request_access)
        .to be_kind_of(::EE::Gitlab::ExternalAuthorization::Response)
    end

    it 'wraps exceptions if the request fails' do
      expect(Excon).to receive(:post) { raise Excon::Error.new('the request broke') }

      expect { client.request_access }
        .to raise_error(EE::Gitlab::ExternalAuthorization::RequestFailed)
    end

    describe 'for ldap users' do
      let(:user) do
        create(:omniauth_user,
               email: 'dummy_user@example.com',
               extern_uid: 'external id',
               provider: 'ldapprovider')
      end

      it 'includes the ldap dn for ldap users' do
        expected_body = {
          user_identifier: 'dummy_user@example.com',
          project_classification_label: 'dummy_label',
          user_ldap_dn: 'external id'
        }.to_json
        expect(Excon).to receive(:post)
                           .with(dummy_url, hash_including(body: expected_body))

        client.request_access
      end
    end
  end
end
