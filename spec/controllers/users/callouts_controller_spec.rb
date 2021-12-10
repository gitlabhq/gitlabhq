# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::CalloutsController do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe "POST #create" do
    let(:params) { { feature_name: feature_name } }

    subject { post :create, params: params, format: :json }

    context 'with valid feature name' do
      let(:feature_name) { Users::Callout.feature_names.each_key.first }

      context 'when callout entry does not exist' do
        it 'creates a callout entry with dismissed state' do
          expect { subject }.to change { Users::Callout.count }.by(1)
        end

        it 'returns success' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when callout entry already exists' do
        let!(:callout) { create(:callout, feature_name: Users::Callout.feature_names.each_key.first, user: user) }

        it 'returns success', :aggregate_failures do
          expect { subject }.not_to change { Users::Callout.count }
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'with invalid feature name' do
      let(:feature_name) { 'bogus_feature_name' }

      it 'returns bad request' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end
end
