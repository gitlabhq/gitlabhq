# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::IncidentManagement::PagerDutyIncidentsController do
  let_it_be(:project) { create(:project) }

  describe 'POST #create' do
    let(:payload) { { messages: [] } }

    def make_request
      post :create, params: project_params, body: payload.to_json, as: :json
    end

    context 'when pagerduty_webhook feature enabled' do
      before do
        stub_feature_flags(pagerduty_webhook: project)
      end

      it 'responds with 202 Accepted' do
        make_request

        expect(response).to have_gitlab_http_status(:accepted)
      end
    end

    context 'when pagerduty_webhook feature disabled' do
      before do
        stub_feature_flags(pagerduty_webhook: false)
      end

      it 'responds with 401 Unauthorized' do
        make_request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  private

  def project_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace, project_id: project)
  end
end
