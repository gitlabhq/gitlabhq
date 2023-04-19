# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KasCookie, feature_category: :deployment_management do
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

  describe '#content_security_policy' do
    let_it_be(:user) { create(:user) }

    controller(ApplicationController) do
      include KasCookie

      def index
        render json: {}, status: :ok
      end
    end

    before do
      stub_config_setting(host: 'gitlab.example.com')
      sign_in(user)
      allow(::Gitlab::Kas).to receive(:enabled?).and_return(true)
      allow(::Gitlab::Kas).to receive(:tunnel_url).and_return(kas_tunnel_url)
    end

    subject(:kas_csp_connect_src) do
      get :index

      request.env['action_dispatch.content_security_policy'].directives['connect-src']
    end

    context "when feature flag is disabled" do
      let_it_be(:kas_tunnel_url) { 'ws://gitlab.example.com/-/k8s-proxy/' }

      before do
        stub_feature_flags(kas_user_access: false)
      end

      it 'does not add KAS url to connect-src directives' do
        expect(kas_csp_connect_src).not_to include(::Gitlab::Kas.tunnel_url)
      end
    end

    context 'when feature flag is enabled' do
      before do
        stub_feature_flags(kas_user_access: true)
      end

      context 'when KAS is on same domain as rails' do
        let_it_be(:kas_tunnel_url) { 'ws://gitlab.example.com/-/k8s-proxy/' }

        it 'does not add KAS url to CSP connect-src directive' do
          expect(kas_csp_connect_src).not_to include(::Gitlab::Kas.tunnel_url)
        end
      end

      context 'when KAS is on subdomain' do
        let_it_be(:kas_tunnel_url) { 'ws://kas.gitlab.example.com/k8s-proxy/' }

        it 'adds KAS url to CSP connect-src directive' do
          expect(kas_csp_connect_src).to include(::Gitlab::Kas.tunnel_url)
        end
      end

      context 'when KAS tunnel url is configured without trailing slash' do
        let_it_be(:kas_tunnel_url) { 'ws://kas.gitlab.example.com/k8s-proxy' }

        it 'adds KAS url to CSP connect-src directive with trailing slash' do
          expect(kas_csp_connect_src).to include("#{::Gitlab::Kas.tunnel_url}/")
        end
      end
    end
  end
end
