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
      let(:correlation_id) { 'foo123' }
      let(:sentry_url) { "https://sentry.address/?environment=bar&query=correlation_id%3A%22#{correlation_id}%22" }
      let(:discover_url) { "https://kibana.address/app/discover#/?_a=%28index:%27pubsub-rails-inf-foo%27%2Cquery%3A%28language%3Akuery%2Cquery%3A%27json.correlation_id%20%3A%20#{correlation_id}%27%29%29&_g=%28time%3A%28from%3A%272022-11-13T00:00:00.000Z%27%2Cto%3A%272022-11-14T00:00:00.000Z%27%29%29" }
      let(:dashboard_url) { "https://kibana.address/app/dashboards#/view/abc-123-dashboard-id?_g=%28time%3A%28from:%272022-11-13T00:00:00.000Z%27%2Cto%3A%272022-11-14T00:00:00.000Z%27%29%29&_a=%28filters%3A%21%28%28query%3A%28match_phrase%3A%28json.correlation_id%3A%27#{correlation_id}%27%29%29%29%29%29" }

      before do
        allow(QA::Support::SystemLogs::Sentry).to receive(:new).and_return(sentry)
        allow(QA::Support::SystemLogs::Kibana).to receive(:new).and_return(kibana)
      end

      context 'and both Sentry and Kibana exist for the logging environment' do
        let(:sentry) { instance_double(QA::Support::SystemLogs::Sentry, url: sentry_url) }
        let(:kibana) do
          instance_double(
            QA::Support::SystemLogs::Kibana,
            discover_url: discover_url,
            dashboard_url: dashboard_url
          )
        end

        it 'returns both Sentry and Kibana URLs' do
          expect(QA::Support::Loglinking.failure_metadata(correlation_id)).to eql(<<~ERROR.chomp)
          Correlation Id: foo123
          Sentry Url: #{sentry_url}
          Kibana - Discover Url: #{discover_url}
          Kibana - Dashboard Url: #{dashboard_url}
          ERROR
        end
      end

      context 'and only Sentry exists for the logging environment' do
        let(:sentry) { instance_double(QA::Support::SystemLogs::Sentry, url: sentry_url) }
        let(:kibana) do
          instance_double(
            QA::Support::SystemLogs::Kibana,
            discover_url: nil,
            dashboard_url: nil
          )
        end

        it 'returns only Sentry URL' do
          expect(QA::Support::Loglinking.failure_metadata(correlation_id)).to eql(<<~ERROR.chomp)
          Correlation Id: foo123
          Sentry Url: #{sentry_url}
          ERROR
        end
      end

      context 'and only Kibana exists for the logging environment' do
        let(:sentry) { instance_double(QA::Support::SystemLogs::Sentry, url: nil) }
        let(:kibana) do
          instance_double(
            QA::Support::SystemLogs::Kibana,
            discover_url: discover_url,
            dashboard_url: dashboard_url
          )
        end

        it 'returns only Kibana Discover and Dashboard URLs' do
          expect(QA::Support::Loglinking.failure_metadata(correlation_id)).to eql(<<~ERROR.chomp)
          Correlation Id: foo123
          Kibana - Discover Url: #{discover_url}
          Kibana - Dashboard Url: #{dashboard_url}
          ERROR
        end
      end

      context 'and neither Sentry nor Kibana exists for the logging environment' do
        let(:sentry) { instance_double(QA::Support::SystemLogs::Sentry, url: nil) }
        let(:kibana) { instance_double(QA::Support::SystemLogs::Kibana, discover_url: nil, dashboard_url: nil) }

        it 'returns only the correlation ID' do
          expect(QA::Support::Loglinking.failure_metadata(correlation_id)).to eql("Correlation Id: #{correlation_id}")
        end
      end
    end
  end

  describe '.logging_environment' do
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

        expect(QA::Support::Loglinking.logging_environment).to eq(logging_env_hash[:expected_env])
      end
    end
  end
end
