# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RegistrationsHelper, feature_category: :user_management do
  describe '#unified_registration?' do
    before do
      allow(helper).to receive(:onboarding_status_presenter)
        .and_return(::Onboarding::StatusPresenter.new({}, nil, build(:user)))
    end

    it { expect(helper.unified_registration?).to be(false) }
  end

  describe '#signup_username_data_attributes' do
    it 'has expected attributes' do
      expect(helper.signup_username_data_attributes.keys).to include(:min_length, :min_length_message, :max_length, :max_length_message, :testid)
    end
  end
end
