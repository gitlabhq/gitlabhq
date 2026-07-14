# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GraphqlController, feature_category: :organization do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:active_organization) { create(:organization) }
  let_it_be(:read_only_organization) do
    create(:organization).tap do |organization|
      organization.start_read_only(read_only_reason: 'migration')
      organization.confirm_read_only
    end
  end

  before do
    sign_in(user)
  end

  describe '#disallow_mutations_for_organization_read_only' do
    shared_examples 'request without read-only error' do
      it 'does not return a read-only error' do
        request_execute

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.fetch('errors', [])).not_to include(
          a_hash_including('message' => /read-only/)
        )
      end
    end

    subject(:request_execute) { post :execute, params: { query: query } }

    let(:query) { '{ __typename }' }

    context 'when the feature flag is enabled' do
      before do
        stub_feature_flags(organization_read_only_enforcement: true)
      end

      context 'with a read-only organization' do
        before do
          stub_current_organization(read_only_organization)
        end

        context 'with a mutating request' do
          before do
            allow(controller).to receive(:any_mutating_query?).and_return(true)
          end

          it 'returns a read-only error' do
            request_execute

            expect(response).to have_gitlab_http_status(:service_unavailable)
            expect(json_response).to include(
              'errors' => include(
                a_hash_including('message' => /read-only/)
              )
            )
          end
        end

        context 'with a read query' do
          before do
            allow(controller).to receive(:any_mutating_query?).and_return(false)
          end

          it_behaves_like 'request without read-only error'
        end
      end

      context 'with an active organization and a mutating request' do
        before do
          stub_current_organization(active_organization)
          allow(controller).to receive(:any_mutating_query?).and_return(true)
        end

        it_behaves_like 'request without read-only error'
      end

      context 'without a current organization and with a mutating request' do
        before do
          stub_current_organization(nil)
          allow(controller).to receive(:any_mutating_query?).and_return(true)
        end

        it_behaves_like 'request without read-only error'
      end
    end

    context 'when the feature flag is disabled with a read-only organization and a mutating request' do
      before do
        stub_feature_flags(organization_read_only_enforcement: false)
        stub_current_organization(read_only_organization)
        allow(controller).to receive(:any_mutating_query?).and_return(true)
      end

      it_behaves_like 'request without read-only error'
    end
  end
end
