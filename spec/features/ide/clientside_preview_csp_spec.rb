# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'IDE Clientside Preview CSP' do
  let_it_be(:user) { create(:user) }

  shared_context 'disable feature' do
    before do
      stub_application_setting(web_ide_clientside_preview_enabled: false)
    end
  end

  it_behaves_like 'setting CSP', 'frame-src' do
    let(:whitelisted_url) { 'https://sandbox.gitlab-static.test' }
    let(:extended_controller_class) { IdeController }

    subject do
      visit ide_path

      response_headers['Content-Security-Policy']
    end

    before do
      stub_application_setting(web_ide_clientside_preview_enabled: true)
      stub_application_setting(web_ide_clientside_preview_bundler_url: whitelisted_url)

      sign_in(user)
    end
  end
end
