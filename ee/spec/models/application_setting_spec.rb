require 'spec_helper'

describe ApplicationSetting do
  subject(:setting) { described_class.create_from_defaults }

  describe 'validations' do
    it { is_expected.to allow_value(100).for(:mirror_max_delay) }
    it { is_expected.not_to allow_value(nil).for(:mirror_max_delay) }
    it { is_expected.not_to allow_value(0).for(:mirror_max_delay) }
    it { is_expected.not_to allow_value(1.1).for(:mirror_max_delay) }
    it { is_expected.not_to allow_value(-1).for(:mirror_max_delay) }
    it { is_expected.not_to allow_value((Gitlab::Mirror::MIN_DELAY - 1.minute) / 60).for(:mirror_max_delay) }

    it { is_expected.to allow_value(10).for(:mirror_max_capacity) }
    it { is_expected.not_to allow_value(nil).for(:mirror_max_capacity) }
    it { is_expected.not_to allow_value(0).for(:mirror_max_capacity) }
    it { is_expected.not_to allow_value(1.1).for(:mirror_max_capacity) }
    it { is_expected.not_to allow_value(-1).for(:mirror_max_capacity) }

    it { is_expected.to allow_value(10).for(:mirror_capacity_threshold) }
    it { is_expected.not_to allow_value(nil).for(:mirror_capacity_threshold) }
    it { is_expected.not_to allow_value(0).for(:mirror_capacity_threshold) }
    it { is_expected.not_to allow_value(1.1).for(:mirror_capacity_threshold) }
    it { is_expected.not_to allow_value(-1).for(:mirror_capacity_threshold) }
    it { is_expected.not_to allow_value(subject.mirror_max_capacity + 1).for(:mirror_capacity_threshold) }
    it { is_expected.to allow_value(nil).for(:custom_project_templates_group_id) }

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

  describe '#repository_size_limit column' do
    it 'support values up to 8 exabytes' do
      setting.update_column(:repository_size_limit, 8.exabytes - 1)

      setting.reload

      expect(setting.repository_size_limit).to eql(8.exabytes - 1)
    end
  end

  describe 'elasticsearch licensing' do
    before do
      setting.elasticsearch_search = true
      setting.elasticsearch_indexing = true
    end

    def expect_is_es_licensed
      expect(License).to receive(:feature_available?).with(:elastic_search).at_least(:once)
    end

    it 'disables elasticsearch when unlicensed' do
      expect_is_es_licensed.and_return(false)

      expect(setting.elasticsearch_indexing?).to be_falsy
      expect(setting.elasticsearch_indexing).to be_falsy
      expect(setting.elasticsearch_search?).to be_falsy
      expect(setting.elasticsearch_search).to be_falsy
    end

    it 'enables elasticsearch when licensed' do
      expect_is_es_licensed.and_return(true)

      expect(setting.elasticsearch_indexing?).to be_truthy
      expect(setting.elasticsearch_indexing).to be_truthy
      expect(setting.elasticsearch_search?).to be_truthy
      expect(setting.elasticsearch_search).to be_truthy
    end
  end

  describe '#elasticsearch_url' do
    it 'presents a single URL as a one-element array' do
      setting.elasticsearch_url = 'http://example.com'

      expect(setting.elasticsearch_url).to eq(%w[http://example.com])
    end

    it 'presents multiple URLs as a many-element array' do
      setting.elasticsearch_url = 'http://example.com,https://invalid.invalid:9200'

      expect(setting.elasticsearch_url).to eq(%w[http://example.com https://invalid.invalid:9200])
    end

    it 'strips whitespace from around URLs' do
      setting.elasticsearch_url = ' http://example.com, https://invalid.invalid:9200 '

      expect(setting.elasticsearch_url).to eq(%w[http://example.com https://invalid.invalid:9200])
    end

    it 'strips trailing slashes from URLs' do
      setting.elasticsearch_url = 'http://example.com/, https://example.com:9200/, https://example.com:9200/prefix//'

      expect(setting.elasticsearch_url).to eq(%w[http://example.com https://example.com:9200 https://example.com:9200/prefix])
    end
  end

  describe '#elasticsearch_config' do
    it 'places all elasticsearch configuration values into a hash' do
      setting.update!(
        elasticsearch_url: 'http://example.com:9200',
        elasticsearch_aws: false,
        elasticsearch_aws_region:     'test-region',
        elasticsearch_aws_access_key: 'test-access-key',
        elasticsearch_aws_secret_access_key: 'test-secret-access-key'
      )

      expect(setting.elasticsearch_config).to eq(
        url: ['http://example.com:9200'],
        aws: false,
        aws_region:     'test-region',
        aws_access_key: 'test-access-key',
        aws_secret_access_key: 'test-secret-access-key'
      )
    end
  end

  describe 'custom project templates' do
    let(:group) { create(:group) }
    let(:projects) { create_list(:project, 3, namespace: group) }

    before do
      setting.update_column(:custom_project_templates_group_id, group.id)

      setting.reload
    end

    context 'when custom_project_templates feature is enabled' do
      before do
        stub_licensed_features(custom_project_templates: true)
      end

      describe '#custom_project_templates_enabled?' do
        it 'returns true' do
          expect(setting.custom_project_templates_enabled?).to be_truthy
        end
      end

      describe '#custom_project_template_id' do
        it 'returns group id' do
          expect(setting.custom_project_templates_group_id).to eq group.id
        end
      end

      describe '#available_custom_project_templates' do
        it 'returns group projects' do
          expect(setting.available_custom_project_templates).to match_array(projects)
        end

        it 'returns an empty array if group is not set' do
          allow(setting).to receive(:custom_project_template_id).and_return(nil)

          expect(setting.available_custom_project_templates).to eq []
        end
      end
    end

    context 'when custom_project_templates feature is disabled' do
      before do
        stub_licensed_features(custom_project_templates: false)
      end

      describe '#custom_project_templates_enabled?' do
        it 'returns false' do
          expect(setting.custom_project_templates_enabled?).to be false
        end
      end

      describe '#custom_project_template_id' do
        it 'returns false' do
          expect(setting.custom_project_templates_group_id).to be false
        end
      end

      describe '#available_custom_project_templates' do
        it 'returns an empty relation' do
          expect(setting.available_custom_project_templates).to be_empty
        end
      end
    end
  end

  describe '#instance_review_permitted?' do
    subject { setting.instance_review_permitted? }

    context 'for instances with a valid license' do
      before do
        license = create(:license, plan: ::License::PREMIUM_PLAN)
        allow(License).to receive(:current).and_return(license)
      end

      it 'is not permitted' do
        expect(subject).to be_falsey
      end
    end

    context 'for instances without a valid license' do
      before do
        allow(License).to receive(:current).and_return(nil)
      end

      context 'when there are more users than minimum count' do
        before do
          expect(Rails.cache).to receive(:fetch).and_return(101)
        end

        it 'is permitted' do
          expect(subject).to be_truthy
        end
      end

      context 'when there are less users than minimum count' do
        before do
          create(:user)
        end

        it 'is not permitted' do
          expect(subject).to be_falsey
        end
      end
    end
  end
end
