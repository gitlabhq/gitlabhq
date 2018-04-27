require 'spec_helper'

describe Users::TermsController do
  let(:user) { create(:user) }
  let(:term) { create(:term) }

  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'redirects when no terms exist' do
      get :index

      expect(response).to have_gitlab_http_status(:redirect)
    end

    it 'shows terms when they exist' do
      term

      expect(response).to have_gitlab_http_status(:success)
    end
  end

  describe 'POST #accept' do
    it 'saves that the user accepted the terms' do
      post :accept, id: term.id

      agreement = user.term_agreements.find_by(term: term)

      expect(agreement.accepted).to eq(true)
    end

    it 'redirects to a path when specified' do
      post :accept, id: term.id, redirect: groups_path

      expect(response).to redirect_to(groups_path)
    end
  end

  describe 'POST #decline' do
    it 'stores that the user declined the terms' do
      post :decline, id: term.id

      agreement = user.term_agreements.find_by(term: term)

      expect(agreement.accepted).to eq(false)
    end

    it 'signs out the user' do
      post :decline, id: term.id

      expect(response).to redirect_to(root_path)
      expect(assigns(:current_user)).to be_nil
    end
  end
end
