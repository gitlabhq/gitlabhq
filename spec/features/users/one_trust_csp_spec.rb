# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OneTrust content security policy', feature_category: :application_instrumentation do
  include ContentSecurityPolicyHelpers

  let(:onetrust_enabled) { true }
  let(:csp) { ActionDispatch::ContentSecurityPolicy.new { |p| p.default_src '' } }
  let(:script_and_connect_src) { ['https://cdn.cookielaw.org', 'https://*.onetrust.com'] }

  subject(:csp_header) { response_headers['Content-Security-Policy'] }

  before do
    stub_config(extra: { one_trust_id: SecureRandom.uuid })
    stub_feature_flags(ecomm_instrumentation: onetrust_enabled)
    stub_csp_for_controller(RegistrationsController, csp)

    visit new_user_registration_path
  end

  it 'has proper Content Security Policy headers', :aggregate_failures do
    expect(find_csp_directive('script-src', header: csp_header)).to include(*script_and_connect_src)
    expect(find_csp_directive('connect-src', header: csp_header)).to include(*script_and_connect_src)
  end

  context 'when disabled' do
    let(:onetrust_enabled) { false }

    it 'does not have Content Security Policy headers' do
      expect(csp_header).not_to include(*script_and_connect_src)
    end
  end

  context 'when CSP is absent' do
    let(:csp) { ActionDispatch::ContentSecurityPolicy.new }

    it 'does not have Content Security Policy headers' do
      expect(csp_header).not_to include(*script_and_connect_src)
    end
  end
end
