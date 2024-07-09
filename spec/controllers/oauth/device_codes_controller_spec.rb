# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::DeviceCodesController, feature_category: :system_access do
  describe 'POST #create' do
    context 'when the feature is enabled' do
      before do
        stub_feature_flags(oauth2_device_grant_flow: true)
      end

      it 'calls the superclass create method' do
        expect_any_instance_of(Doorkeeper::DeviceAuthorizationGrant::DeviceCodesController) do |instance|
          expect(instance).to receive(:create)
        end
        post :create
      end
    end

    context 'when the feature is disabled' do
      before do
        stub_feature_flags(oauth2_device_grant_flow: false)
      end

      it 'returns :not_found' do
        post :create
        expect(response).to have_gitlab_http_status(:no_content)
      end
    end
  end
end
