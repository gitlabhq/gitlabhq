# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Bizible content security policy', feature_category: :subscription_management do
  include ContentSecurityPolicyHelpers

  let(:bizible_enabled) { true }
  let(:csp) { ActionDispatch::ContentSecurityPolicy.new { |p| p.default_src '' } }
  let(:script_src) { ["'unsafe-eval'", 'https://cdn.bizible.com/scripts/bizible.js'] }

  subject(:csp_header) { response_headers['Content-Security-Policy'] }

  before do
    stub_config(extra: { bizible: bizible_enabled })
    stub_feature_flags(ecomm_instrumentation: true)
    stub_csp_for_controller(RegistrationsController, csp)

    visit new_user_registration_path
  end

  it 'has proper Content Security Policy headers' do
    expect(find_csp_directive('script-src', header: csp_header)).to include(*script_src)
  end

  context 'when disabled' do
    let(:bizible_enabled) { false }

    it 'does not have Content Security Policy headers' do
      expect(csp_header).not_to include(*script_src)
    end
  end

  context 'when CSP is absent' do
    let(:csp) { ActionDispatch::ContentSecurityPolicy.new }

    it 'does not have Content Security Policy headers' do
      expect(csp_header).not_to include(*script_src)
    end
  end
end
