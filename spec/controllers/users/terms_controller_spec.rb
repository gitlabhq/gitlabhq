require 'spec_helper'

describe Users::TermsController do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'redirects when no terms exist' do
      get :index

      expect(response).to have_gitlab_http_status(:redirect)
    end

    it 'shows terms when they exist' do
      create(:term)

      expect(response).to have_gitlab_http_status(:success)
    end
  end
end
