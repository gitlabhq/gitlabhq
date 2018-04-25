require 'spec_helper'

describe ApplicationSetting do
  subject(:setting) { described_class.create_from_defaults }

  describe 'validations' do
    it { is_expected.to allow_value(100).for(:mirror_max_delay) }
    it { is_expected.not_to allow_value(nil).for(:mirror_max_delay) }
    it { is_expected.not_to allow_value(0).for(:mirror_max_delay) }
    it { is_expected.not_to allow_value(1.0).for(:mirror_max_delay) }
    it { is_expected.not_to allow_value(-1).for(:mirror_max_delay) }
    it { is_expected.not_to allow_value((Gitlab::Mirror::MIN_DELAY - 1.minute) / 60).for(:mirror_max_delay) }

    it { is_expected.to allow_value(10).for(:mirror_max_capacity) }
    it { is_expected.not_to allow_value(nil).for(:mirror_max_capacity) }
    it { is_expected.not_to allow_value(0).for(:mirror_max_capacity) }
    it { is_expected.not_to allow_value(1.0).for(:mirror_max_capacity) }
    it { is_expected.not_to allow_value(-1).for(:mirror_max_capacity) }

    it { is_expected.to allow_value(10).for(:mirror_capacity_threshold) }
    it { is_expected.not_to allow_value(nil).for(:mirror_capacity_threshold) }
    it { is_expected.not_to allow_value(0).for(:mirror_capacity_threshold) }
    it { is_expected.not_to allow_value(1.0).for(:mirror_capacity_threshold) }
    it { is_expected.not_to allow_value(-1).for(:mirror_capacity_threshold) }
    it { is_expected.not_to allow_value(subject.mirror_max_capacity + 1).for(:mirror_capacity_threshold) }

    describe 'when additional email text is enabled' do
      before do
        stub_licensed_features(email_additional_text: true)
      end

      it { is_expected.to allow_value("a" * subject.email_additional_text_character_limit).for(:email_additional_text) }
      it { is_expected.not_to allow_value("a" * (subject.email_additional_text_character_limit + 1)).for(:email_additional_text) }
    end

    describe 'when external authorization service is enabled' do
      before do
        stub_licensed_features(external_authorization_service: true)
        setting.external_authorization_service_enabled = true
      end

      it { is_expected.not_to allow_value('not a URL').for(:external_authorization_service_url) }
      it { is_expected.to allow_value('https://example.com').for(:external_authorization_service_url) }
      it { is_expected.to allow_value('').for(:external_authorization_service_url) }
      it { is_expected.not_to allow_value(nil).for(:external_authorization_service_default_label) }
      it { is_expected.not_to allow_value(11).for(:external_authorization_service_timeout) }
      it { is_expected.not_to allow_value(0).for(:external_authorization_service_timeout) }
      it { is_expected.not_to allow_value('not a certificate').for(:external_auth_client_cert) }
      it { is_expected.to allow_value('').for(:external_auth_client_cert) }
      it { is_expected.to allow_value('').for(:external_auth_client_key) }

      context 'when setting a valid client certificate for external authorization' do
        let(:certificate_data)  { File.read('ee/spec/fixtures/passphrase_x509_certificate.crt') }

        before do
          setting.external_auth_client_cert = certificate_data
        end

        it 'requires a valid client key when a certificate is set' do
          expect(setting).not_to allow_value('fefefe').for(:external_auth_client_key)
        end

        it 'requires a matching certificate' do
          other_private_key = File.read('ee/spec/fixtures/x509_certificate_pk.key')

          expect(setting).not_to allow_value(other_private_key).for(:external_auth_client_key)
        end

        it 'the credentials are valid when the private key can be read and matches the certificate' do
          tls_attributes = [:external_auth_client_key_pass,
                            :external_auth_client_key,
                            :external_auth_client_cert]
          setting.external_auth_client_key = File.read('ee/spec/fixtures/passphrase_x509_certificate_pk.key')
          setting.external_auth_client_key_pass = '5iveL!fe'

          setting.validate

          expect(setting.errors).not_to include(*tls_attributes)
        end
      end
    end
  end

  describe '#should_check_namespace_plan?' do
    before do
      stub_application_setting(check_namespace_plan: check_namespace_plan_column)
      allow(::Gitlab).to receive(:dev_env_or_com?) { gl_com }

      # This stub was added in order to force a fallback to Gitlab.dev_env_or_com?
      # call testing.
      # Gitlab.dev_env_or_com? responds to `false` on test envs
      # and we want to make sure we're still testing
      # should_check_namespace_plan? method through the test-suite (see
      # https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/18461#note_69322821).
      allow(Rails).to receive_message_chain(:env, :test?).and_return(false)
    end

    subject { setting.should_check_namespace_plan? }

    context 'when check_namespace_plan true AND on GitLab.com' do
      let(:check_namespace_plan_column) { true }
      let(:gl_com) { true }

      it 'returns true' do
        is_expected.to eq(true)
      end
    end

    context 'when check_namespace_plan true AND NOT on GitLab.com' do
      let(:check_namespace_plan_column) { true }
      let(:gl_com) { false }

      it 'returns false' do
        is_expected.to eq(false)
      end
    end

    context 'when check_namespace_plan false AND on GitLab.com' do
      let(:check_namespace_plan_column) { false }
      let(:gl_com) { true }

      it 'returns false' do
        is_expected.to eq(false)
      end
    end
  end
end
