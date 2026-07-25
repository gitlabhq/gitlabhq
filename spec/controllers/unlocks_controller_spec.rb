# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UnlocksController, feature_category: :system_access do
  include DeviseHelpers

  before do
    set_devise_mapping(context: request)
  end

  describe 'read-only organization enforcement exemption' do
    it 'does not run read-only organization enforcement on #create' do
      allow(controller).to receive(:enforce_read_only_organization).and_call_original

      post :create, params: { user: { email: 'unknown@example.com' } }

      expect(controller).not_to have_received(:enforce_read_only_organization)
    end
  end
end
