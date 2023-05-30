# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RegistrationsHelper, feature_category: :user_management do
  describe '#signup_username_data_attributes' do
    it 'has expected attributes' do
      expect(helper.signup_username_data_attributes.keys).to include(:min_length, :min_length_message, :max_length, :max_length_message, :qa_selector)
    end
  end

  describe '#register_omniauth_params' do
    it 'adds intent to register' do
      allow(helper).to receive(:glm_tracking_params).and_return({})

      expect(helper.register_omniauth_params({})).to eq({})
    end
  end
end
