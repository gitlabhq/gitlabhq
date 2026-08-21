# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GraphqlController, feature_category: :organization do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:active_organization) { create(:organization) }
  let_it_be_with_reload(:maintenance_mode_organization) do
    create(:organization).tap do |organization|
      organization.start_maintenance(maintenance_reason: 'migration')
      organization.confirm_maintenance
    end
  end

  let_it_be_with_reload(:indefinite_organization) do
    create(:organization).tap do |organization|
      organization.start_maintenance(maintenance_reason: 'legal')
      organization.confirm_maintenance
    end
  end

  before do
    sign_in(user)
  end

  describe '#disallow_requests_for_organization_maintenance_mode' do
    shared_examples 'request without maintenance mode error' do
      it 'does not return a maintenance mode error' do
        request_execute

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.fetch('errors', [])).not_to include(
          a_hash_including('message' => /unavailable due to maintenance/)
        )
      end
    end

    subject(:request_execute) { post :execute, params: { query: query } }

    let(:query) { '{ __typename }' }

    context 'when the feature flag is enabled' do
      before do
        stub_feature_flags(organization_maintenance_enforcement: true)
      end

      context 'with an organization in maintenance mode' do
        before do
          stub_current_organization(maintenance_mode_organization)
        end

        it 'returns a 503 maintenance mode error with a Retry-After header for a read query', :aggregate_failures do
          request_execute

          expect(response).to have_gitlab_http_status(:service_unavailable)
          expect(response.headers['Retry-After']).to eq('60')
          expect(json_response).to include(
            'errors' => include(
              a_hash_including('message' => /unavailable due to maintenance/)
            )
          )
        end

        it 'blocks the read query before writing last_activity_on' do
          activity_user = create(:user, last_activity_on: 2.days.ago.to_date)
          sign_in(activity_user)

          expect { request_execute }.not_to change { activity_user.reload.last_activity_on }
          expect(response).to have_gitlab_http_status(:service_unavailable)
        end

        it 'returns a 503 maintenance mode error for a mutating request', :aggregate_failures do
          allow(controller).to receive(:any_mutating_query?).and_return(true)

          request_execute

          expect(response).to have_gitlab_http_status(:service_unavailable)
          expect(response.headers['Retry-After']).to eq('60')
          expect(json_response).to include(
            'errors' => include(
              a_hash_including('message' => /unavailable due to maintenance/)
            )
          )
        end
      end

      context 'with an organization in maintenance mode for an indefinite reason' do
        before do
          stub_current_organization(indefinite_organization)
        end

        it 'returns a 403 error with no Retry-After header', :aggregate_failures do
          request_execute

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(response.headers['Retry-After']).to be_nil
          expect(json_response).to include(
            'errors' => include(
              a_hash_including('message' => 'This organization is unavailable.')
            )
          )
        end
      end

      context 'with an active organization' do
        before do
          stub_current_organization(active_organization)
        end

        it_behaves_like 'request without maintenance mode error'
      end

      context 'without a current organization' do
        before do
          stub_current_organization(nil)
        end

        it_behaves_like 'request without maintenance mode error'
      end
    end

    context 'when the feature flag is disabled with an organization in maintenance mode' do
      before do
        stub_feature_flags(organization_maintenance_enforcement: false)
        stub_current_organization(maintenance_mode_organization)
      end

      it_behaves_like 'request without maintenance mode error'
    end
  end
end
