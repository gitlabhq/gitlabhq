# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::BroadcastMessagesController do
  before do
    sign_in(create(:admin))
  end

  describe 'GET /preview' do
    render_views

    it 'renders preview partial' do
      get :preview, params: { broadcast_message: { message: "Hello, world!" } }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to render_template(:_preview)
    end
  end
end
