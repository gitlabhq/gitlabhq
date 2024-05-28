# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Bizible content security policy', feature_category: :subscription_management do
  before do
    stub_config(extra: { one_trust_id: SecureRandom.uuid })
  end

  it 'has proper Content Security Policy headers' do
    visit root_path

    expect(response_headers['Content-Security-Policy']).to include('https://cdn.bizible.com/scripts/bizible.js')
  end
end
