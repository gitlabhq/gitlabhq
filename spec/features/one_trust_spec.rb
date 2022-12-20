# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OneTrust', feature_category: :system_access do
  context 'almost there page' do
    context 'when OneTrust is enabled' do
      let_it_be(:onetrust_url) { 'https://*.onetrust.com' }
      let_it_be(:one_trust_id) { SecureRandom.uuid }

      before do
        stub_config(extra: { one_trust_id: one_trust_id })
        stub_feature_flags(ecomm_instrumentation: true)
        visit users_almost_there_path
      end

      it 'has the OneTrust CSP settings', :aggregate_failures do
        expect(response_headers['Content-Security-Policy']).to include(onetrust_url.to_s)
        expect(page.html).to include("https://cdn.cookielaw.org/consent/#{one_trust_id}/OtAutoBlock.js")
      end
    end
  end
end
