require 'rails_helper'

RSpec.describe IntegrationsController, type: :controller do

  describe 'POST trigger' do
    it 'returns a 200 status code' do
      post :trigger, format: :json

      expect(response).to have_http_status(200)
    end
  end
end
