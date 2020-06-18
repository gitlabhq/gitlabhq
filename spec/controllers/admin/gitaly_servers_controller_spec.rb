# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::GitalyServersController do
  describe '#index' do
    before do
      sign_in(create(:admin))
    end

    it 'shows the gitaly servers page' do
      get :index

      expect(response).to have_gitlab_http_status(:ok)
    end
  end
end
