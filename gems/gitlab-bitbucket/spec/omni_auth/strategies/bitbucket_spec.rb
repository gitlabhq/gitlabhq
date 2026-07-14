# frozen_string_literal: true

# Smoke test: verify the strategy is loadable from the gem's lib/ path
# and that its default_options are sane.  This guards against path/require
# regressions when Gitlab::OmniauthInitializer does
# `require_dependency "omni_auth/strategies/bitbucket"`.
RSpec.describe OmniAuth::Strategies::Bitbucket do
  it 'resolves after require "omni_auth/strategies/bitbucket"' do
    # spec_helper already requires it; confirm the constant is present
    expect(described_class).to be < OmniAuth::Strategies::OAuth2
  end

  describe 'default_options' do
    subject(:client_options) { described_class.default_options[:client_options] }

    it 'has the expected site' do
      expect(client_options['site']).to eq('https://api.bitbucket.org')
    end

    it 'has the expected authorize_url' do
      expect(client_options['authorize_url']).to eq('https://bitbucket.org/site/oauth2/authorize')
    end

    it 'has the expected token_url' do
      expect(client_options['token_url']).to eq('https://bitbucket.org/site/oauth2/access_token')
    end
  end
end
