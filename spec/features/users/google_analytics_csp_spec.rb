# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Google Analytics 4 content security policy', feature_category: :purchase do
  include ContentSecurityPolicyHelpers

  subject(:csp_header) { response_headers['Content-Security-Policy'] }

  it 'includes the GA4 content security policy headers' do
    visit root_path

    expect(find_csp_directive('script-src', header: csp_header)).to include(
      '*.googletagmanager.com'
    )

    expect(find_csp_directive('connect-src', header: csp_header)).to include(
      '*.googletagmanager.com',
      '*.google-analytics.com',
      '*.analytics.google.com',
      '*.g.doubleclick.net'
    )

    expect(find_csp_directive('img-src', header: csp_header)).to include(
      '*.googletagmanager.com',
      '*.google-analytics.com',
      '*.analytics.google.com',
      '*.g.doubleclick.net'
    )
  end
end
