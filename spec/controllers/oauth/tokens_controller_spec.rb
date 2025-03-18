# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::TokensController, feature_category: :user_management do
  let(:user) { create(:user) }

  it 'includes Two-factor enforcement concern' do
    expect(described_class.included_modules.include?(EnforcesTwoFactorAuthentication)).to eq(true)
  end

  describe '#append_info_to_payload' do
    controller(described_class) do
      attr_reader :last_payload

      def create
        render html: 'authenticated'
      end

      def append_info_to_payload(payload)
        super

        @last_payload = payload
      end
    end

    it 'does log correlation id' do
      Labkit::Correlation::CorrelationId.use_id('new-id') do
        post :create
      end

      expect(controller.last_payload).to include('correlation_id' => 'new-id')
    end

    it 'adds context metadata to the payload' do
      sign_in user

      post :create

      expect(controller.last_payload[:metadata]).to include(Gitlab::ApplicationContext.current)
    end
  end
end
