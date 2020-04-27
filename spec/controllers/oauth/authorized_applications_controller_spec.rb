# frozen_string_literal: true

require 'spec_helper'

describe Oauth::AuthorizedApplicationsController do
  let(:user) { create(:user) }
  let(:guest) { create(:user) }
  let(:application) { create(:oauth_application, owner: guest) }

  before do
    sign_in(user)
  end

  describe 'GET #index' do
    it 'responds with 404' do
      get :index

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
