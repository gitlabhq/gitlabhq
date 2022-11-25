# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Static Object External Storage Content Security Policy', feature_category: :web_ide do
  let_it_be(:user) { create(:user) }

  shared_context 'disable feature' do
    before do
      allow_any_instance_of(ApplicationSetting).to receive(:static_objects_external_storage_url).and_return(nil)
    end
  end

  it_behaves_like 'setting CSP', 'connect-src' do
    let_it_be(:allowlisted_url) { 'https://static-objects.test' }
    let_it_be(:extended_controller_class) { IdeController }

    subject do
      visit ide_path

      response_headers['Content-Security-Policy']
    end

    before do
      allow_any_instance_of(ApplicationSetting).to receive(:static_objects_external_storage_url).and_return(allowlisted_url)
      allow_any_instance_of(ApplicationSetting).to receive(:static_objects_external_storage_auth_token).and_return('letmein')

      sign_in(user)
    end
  end
end
