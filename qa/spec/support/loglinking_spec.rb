# frozen_string_literal: true

RSpec.describe QA::Support::Loglinking do
  describe '.failure_metadata' do
    context 'when correlation_id does not exist' do
      it 'returns nil when correlation_id is empty' do
        expect(QA::Support::Loglinking.failure_metadata('')).to eq(nil)
      end

      it 'returns nil when correlation_id is nil' do
        expect(QA::Support::Loglinking.failure_metadata(nil)).to eq(nil)
      end
    end

    context 'when correlation_id exists' do
      context 'and logging environment exists' do
        it 'returns Sentry URL' do
          allow(QA::Support::Loglinking).to receive(:get_logging_environment).and_return(:foo)
          allow(QA::Support::Loglinking).to receive(:get_sentry_base_url).and_return('https://sentry.address/?environment=bar')
          allow(QA::Support::Loglinking).to receive(:get_kibana_base_url).and_return(nil)
          allow(QA::Support::Loglinking).to receive(:get_kibana_index).and_return(nil)

          expect(QA::Support::Loglinking.failure_metadata('foo123')).to eql(<<~ERROR.chomp)
          Correlation Id: foo123
          Sentry Url: https://sentry.address/?environment=bar&query=correlation_id%3A%22foo123%22
          ERROR
        end

        it 'returns Kibana URL' do
          time = Time.new(2022, 11, 14, 0, 0, 0, '+00:00')

          allow(QA::Support::Loglinking).to receive(:get_logging_environment).and_return(:foo)
          allow(QA::Support::Loglinking).to receive(:get_sentry_base_url).and_return(nil)
          allow(QA::Support::Loglinking).to receive(:get_kibana_base_url).and_return('https://kibana.address/')
          allow(QA::Support::Loglinking).to receive(:get_kibana_index).and_return('pubsub-rails-inf-foo')
          allow(Time).to receive(:now).and_return(time)

          expect(QA::Support::Loglinking.failure_metadata('foo123')).to eql(<<~ERROR.chomp)
          Correlation Id: foo123
          Kibana Url: https://kibana.address/app/discover#/?_a=%28index:pubsub-rails-inf-foo%2Cquery%3A%28language%3Akuery%2Cquery%3A%27json.correlation_id%20%3A%20foo123%27%29%29&_g=%28time%3A%28from%3A%272022-11-13T00:00:00.000Z%27%2Cto%3A%272022-11-14T00:00:00.000Z%27%29%29
          ERROR
        end
      end

      context 'and logging environment does not exist' do
        it 'returns only the correlation ID' do
          allow(QA::Support::Loglinking).to receive(:get_logging_environment).and_return(nil)

          expect(QA::Support::Loglinking.failure_metadata('foo123')).to eql('Correlation Id: foo123')
        end
      end
    end
  end

  describe '.get_sentry_base_url' do
    let(:url_hash) do
      {
        :staging => 'https://sentry.gitlab.net/gitlab/staginggitlabcom/?environment=gstg',
        :staging_ref => 'https://sentry.gitlab.net/gitlab/staging-ref/?environment=all',
        :pre => 'https://sentry.gitlab.net/gitlab/pregitlabcom/?environment=all',
        :production => 'https://sentry.gitlab.net/gitlab/gitlabcom/?environment=gprd',
        :foo => nil,
        nil => nil
      }
    end

    it 'returns Sentry base URL based on environment' do
      url_hash.each do |environment, url|
        expect(QA::Support::Loglinking.get_sentry_base_url(environment)).to eq(url)
      end
    end
  end

  describe '.get_kibana_base_url' do
    let(:url_hash) do
      {
        :staging => 'https://nonprod-log.gitlab.net/',
        :staging_ref => nil,
        :production => 'https://log.gprd.gitlab.net/',
        :pre => 'https://nonprod-log.gitlab.net/',
        :foo => nil,
        nil => nil
      }
    end

    it 'returns Kibana URL based on environment' do
      url_hash.each do |environment, url|
        expect(QA::Support::Loglinking.get_kibana_base_url(environment)).to eq(url)
      end
    end
  end

  describe '.get_kibana_index' do
    let(:index_hash) do
      {
        :staging => 'pubsub-rails-inf-gstg',
        :staging_ref => nil,
        :production => 'pubsub-rails-inf-gprd',
        :pre => 'pubsub-rails-inf-pre',
        :foo => nil,
        nil => nil
      }
    end

    it 'returns Kibana index based on environment' do
      index_hash.each do |environment, index|
        expect(QA::Support::Loglinking.get_kibana_index(environment)).to eq(index)
      end
    end
  end

  describe '.get_logging_environment' do
    let(:staging_address) { 'https://staging.gitlab.com' }
    let(:staging_ref_address) { 'https://staging-ref.gitlab.com' }
    let(:production_address) { 'https://gitlab.com' }
    let(:pre_prod_address) { 'https://pre.gitlab.com' }
    let(:logging_env_array) do
      [
        {
          address: staging_address,
          expected_env: :staging
        },
        {
          address: staging_ref_address,
          expected_env: :staging_ref
        },
        {
          address: production_address,
          expected_env: :production
        },
        {
          address: pre_prod_address,
          expected_env: :pre
        },
        {
          address: 'https://foo.com',
          expected_env: nil
        }
      ]
    end

    it 'returns logging environment if environment found' do
      logging_env_array.each do |logging_env_hash|
        allow(QA::Runtime::Scenario).to receive(:attributes).and_return({ gitlab_address: logging_env_hash[:address] })

        expect(QA::Support::Loglinking.get_logging_environment).to eq(logging_env_hash[:expected_env])
      end
    end
  end
end
