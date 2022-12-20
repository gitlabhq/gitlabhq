# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Google Analytics 4 content security policy', feature_category: :purchase do
  it 'includes the GA4 content security policy headers' do
    visit root_path

    expect(response_headers['Content-Security-Policy']).to include(
      '*.googletagmanager.com',
      '*.google-analytics.com',
      '*.analytics.google.com'
    )
  end
end
