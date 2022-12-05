# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OneTrust content security policy', feature_category: :application_instrumentation do
  let(:user) { create(:user) }

  before do
    stub_config(extra: { one_trust_id: SecureRandom.uuid })
  end

  it 'has proper Content Security Policy headers' do
    visit root_path

    expect(response_headers['Content-Security-Policy']).to include('https://cdn.cookielaw.org https://*.onetrust.com')
  end
end
