# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::HealthCheckController do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'GET show' do
    it 'loads the health information' do
      get :show

      expect(assigns[:errors]).not_to be_nil
    end
  end
end
