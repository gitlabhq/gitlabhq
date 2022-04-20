# frozen_string_literal: true

RSpec.describe QA::Support::Loglinking do
  describe '.failure_metadata' do
    context 'return nil string' do
      it 'if correlation_id is empty' do
        expect(QA::Support::Loglinking.failure_metadata('')).to eq(nil)
      end
      it 'if correlation_id is nil' do
        expect(QA::Support::Loglinking.failure_metadata(nil)).to eq(nil)
      end
    end

    context 'return error string' do
      it 'with sentry URL' do
        allow(QA::Support::Loglinking).to receive(:sentry_url).and_return('https://sentry.address/?environment=bar')
        allow(QA::Support::Loglinking).to receive(:kibana_url).and_return(nil)

        expect(QA::Support::Loglinking.failure_metadata('foo123')).to eql(<<~ERROR.chomp)
          Correlation Id: foo123
          Sentry Url: https://sentry.address/?environment=bar&query=correlation_id%3A%22foo123%22
        ERROR
      end

      it 'with kibana URL' do
        allow(QA::Support::Loglinking).to receive(:sentry_url).and_return(nil)
        allow(QA::Support::Loglinking).to receive(:kibana_url).and_return('https://kibana.address/')

        expect(QA::Support::Loglinking.failure_metadata('foo123')).to eql(<<~ERROR.chomp)
          Correlation Id: foo123
          Kibana Url: https://kibana.address/app/discover#/?_a=(query:(language:kuery,query:'json.correlation_id%20:%20foo123'))&_g=(time:(from:now-24h%2Fh,to:now))
        ERROR
      end
    end
  end

  describe '.sentry_url' do
    let(:url_hash) do
      {
        :staging =>         'https://sentry.gitlab.net/gitlab/staginggitlabcom/?environment=gstg',
        :staging_canary =>  'https://sentry.gitlab.net/gitlab/staginggitlabcom/?environment=gstg-cny',
        :staging_ref =>     'https://sentry.gitlab.net/gitlab/staging-ref/?environment=gstg-ref',
        :pre =>             'https://sentry.gitlab.net/gitlab/pregitlabcom/?environment=pre',
        :canary =>          'https://sentry.gitlab.net/gitlab/gitlabcom/?environment=gprd',
        :production =>      'https://sentry.gitlab.net/gitlab/gitlabcom/?environment=gprd-cny',
        :foo =>             nil,
        nil =>              nil
      }
    end

    it 'returns sentry URL if environment found' do
      url_hash.each do |environment, url|
        allow(QA::Support::Loglinking).to receive(:logging_environment).and_return(environment)

        expect(QA::Support::Loglinking.sentry_url).to eq(url)
      end
    end
  end

  describe '.kibana_url' do
    let(:url_hash) do
      {
        :staging =>         'https://nonprod-log.gitlab.net/',
        :staging_canary =>  'https://nonprod-log.gitlab.net/',
        :staging_ref =>     nil,
        :pre =>             nil,
        :canary =>          'https://log.gprd.gitlab.net/',
        :production =>      'https://log.gprd.gitlab.net/',
        :foo =>             nil,
        nil =>              nil
      }
    end

    it 'returns kibana URL if environment found' do
      url_hash.each do |environment, url|
        allow(QA::Support::Loglinking).to receive(:logging_environment).and_return(environment)

        expect(QA::Support::Loglinking.kibana_url).to eq(url)
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
          canary: false,
          expected_env: :staging
        },
        {
          address: staging_address,
          canary: true,
          expected_env: :staging_canary
        },
        {
          address: staging_ref_address,
          canary: true,
          expected_env: :staging_ref
        },
        {
          address: production_address,
          canary: false,
          expected_env: :production
        },
        {
          address: production_address,
          canary: true,
          expected_env: :canary
        },
        {
          address: pre_prod_address,
          canary: true,
          expected_env: :pre
        },
        {
          address: 'https://foo.com',
          canary: true,
          expected_env: nil
        }
      ]
    end

    it 'returns logging environment if environment found' do
      logging_env_array.each do |logging_env_hash|
        allow(QA::Runtime::Scenario).to receive(:attributes).and_return({ gitlab_address: logging_env_hash[:address] })
        allow(QA::Support::Loglinking).to receive(:canary?).and_return(logging_env_hash[:canary])

        expect(QA::Support::Loglinking.logging_environment).to eq(logging_env_hash[:expected_env])
      end
    end
  end

  describe '.logging_environment?' do
    context 'returns boolean' do
      it 'returns true if logging_environment is not nil' do
        allow(QA::Support::Loglinking).to receive(:logging_environment).and_return(:staging)

        expect(QA::Support::Loglinking.logging_environment?).to eq(true)
      end

      it 'returns false if logging_environment is nil' do
        allow(QA::Support::Loglinking).to receive(:logging_environment).and_return(nil)

        expect(QA::Support::Loglinking.logging_environment?).to eq(false)
      end
    end
  end

  describe '.cookies' do
    let(:cookies) { [{ name: 'Foo', value: 'Bar' }, { name: 'gitlab_canary', value: 'true' }] }

    it 'returns browser cookies' do
      allow(Capybara.current_session).to receive_message_chain(:driver, :browser, :manage, :all_cookies).and_return(cookies)

      expect(QA::Support::Loglinking.cookies).to eq({ "Foo" => { name: "Foo", value: "Bar" }, "gitlab_canary" => { name: "gitlab_canary", value: "true" } })
    end
  end

  describe '.canary?' do
    context 'gitlab_canary cookie is present' do
      it 'and true returns true' do
        allow(QA::Support::Loglinking).to receive(:cookies).and_return({ 'gitlab_canary' => { name: 'gitlab_canary', value: 'true' } })

        expect(QA::Support::Loglinking.canary?).to eq(true)
      end
      it 'and not true returns false' do
        allow(QA::Support::Loglinking).to receive(:cookies).and_return({ 'gitlab_canary' => { name: 'gitlab_canary', value: 'false' } })

        expect(QA::Support::Loglinking.canary?).to eq(false)
      end
    end
    context 'gitlab_canary cookie is not present' do
      it 'returns false' do
        allow(QA::Support::Loglinking).to receive(:cookies).and_return({ 'foo' => { name: 'foo', path: '/pathname' } })

        expect(QA::Support::Loglinking.canary?).to eq(false)
      end
    end
  end
end
