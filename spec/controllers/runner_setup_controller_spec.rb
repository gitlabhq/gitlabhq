# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RunnerSetupController do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET #platforms' do
    it 'renders the platforms' do
      get :platforms

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to have_key("windows")
      expect(json_response).to have_key("kubernetes")
    end
  end
end
