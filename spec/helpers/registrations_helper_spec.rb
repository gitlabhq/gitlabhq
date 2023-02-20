# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RegistrationsHelper do
  describe '#signup_username_data_attributes' do
    it 'has expected attributes' do
      expect(helper.signup_username_data_attributes.keys).to include(:min_length, :min_length_message, :max_length, :max_length_message, :qa_selector)
    end
  end

  describe '#arkose_labs_challenge_enabled?' do
    before do
      stub_application_setting(
        arkose_labs_private_api_key: nil,
        arkose_labs_public_api_key: nil,
        arkose_labs_namespace: nil
      )
      stub_env('ARKOSE_LABS_PRIVATE_KEY', nil)
      stub_env('ARKOSE_LABS_PUBLIC_KEY', nil)
    end

    it 'is false' do
      expect(helper.arkose_labs_challenge_enabled?).to eq false
    end
  end
end
