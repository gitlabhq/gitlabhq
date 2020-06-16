# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'IDE Clientside Preview CSP' do
  let_it_be(:user) { create(:user) }

  shared_context 'disable feature' do
    before do
      allow_next_instance_of(ApplicationSetting) do |instance|
        allow(instance).to receive(:web_ide_clientside_preview_enabled?).and_return(false)
      end
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
      allow_next_instance_of(ApplicationSetting) do |instance|
        allow(instance).to receive(:web_ide_clientside_preview_enabled?).and_return(true)
        allow(instance).to receive(:web_ide_clientside_preview_bundler_url).and_return(whitelisted_url)
      end

      sign_in(user)
    end
  end
end
