# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AcmeChallengesController do
  describe '#show' do
    let!(:acme_order) { create(:pages_domain_acme_order) }

    def make_request(domain, token)
      get(:show, params: { domain: domain, token: token })
    end

    before do
      make_request(domain, token)
    end

    context 'with right domain and token' do
      let(:domain) { acme_order.pages_domain.domain }
      let(:token) { acme_order.challenge_token }

      it 'renders acme challenge file content' do
        expect(response.body).to eq(acme_order.challenge_file_content)
      end
    end

    context 'when domain is invalid' do
      let(:domain) { 'somewrongdomain.com' }
      let(:token) { acme_order.challenge_token }

      it 'renders not found' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when token is invalid' do
      let(:domain) { acme_order.pages_domain.domain }
      let(:token) { 'wrongtoken' }

      it 'renders not found' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
