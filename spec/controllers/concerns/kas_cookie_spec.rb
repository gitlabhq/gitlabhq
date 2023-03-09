# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KasCookie, feature_category: :kubernetes_management do
  describe '#set_kas_cookie' do
    controller(ApplicationController) do
      include KasCookie

      def index
        set_kas_cookie

        render json: {}, status: :ok
      end
    end

    before do
      allow(::Gitlab::Kas).to receive(:enabled?).and_return(true)
    end

    subject(:kas_cookie) do
      get :index

      request.env['action_dispatch.cookies'][Gitlab::Kas::COOKIE_KEY]
    end

    context 'when user is signed out' do
      it { is_expected.to be_blank }
    end

    context 'when user is signed in' do
      let_it_be(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it 'sets the KAS cookie', :aggregate_failures do
        allow(::Gitlab::Kas::UserAccess).to receive(:cookie_data).and_return('foobar')

        expect(kas_cookie).to be_present
        expect(kas_cookie).to eq('foobar')
        expect(::Gitlab::Kas::UserAccess).to have_received(:cookie_data)
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(kas_user_access: false)
        end

        it { is_expected.to be_blank }
      end
    end
  end
end
