# frozen_string_literal: true

require 'spec_helper'

describe GraphqlController do
  before do
    stub_feature_flags(graphql: true)
  end

  describe 'POST #execute' do
    context 'when user is logged in' do
      let(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it 'returns 200 when user can access API' do
        post :execute

        expect(response).to have_gitlab_http_status(200)
      end

      it 'returns access denied template when user cannot access API' do
        # User cannot access API in a couple of cases
        # * When user is internal(like ghost users)
        # * When user is blocked
        expect(Ability).to receive(:allowed?).with(user, :access_api, :global).and_return(false)

        post :execute

        expect(response.status).to eq(403)
        expect(response).to render_template('errors/access_denied')
      end
    end

    context 'when user is not logged in' do
      it 'returns 200' do
        post :execute

        expect(response).to have_gitlab_http_status(200)
      end
    end
  end
end
