require 'spec_helper'

describe SentryHelper do
  describe '#sentry_dsn_public' do
    it 'returns nil if no sentry_dsn is set' do
      mock_sentry_dsn(nil)

      expect(helper.sentry_dsn_public).to eq nil
    end

    it 'returns the uri string with no password if sentry_dsn is set' do
      mock_sentry_dsn('https://test:dsn@host/path')

      expect(helper.sentry_dsn_public).to eq 'https://test@host/path'
    end
  end

  def mock_sentry_dsn(value)
    allow_message_expectations_on_nil
    allow(ApplicationSetting.current).to receive(:sentry_dsn).and_return(value)
  end
end
