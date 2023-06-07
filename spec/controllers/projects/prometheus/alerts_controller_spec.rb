# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Prometheus::AlertsController, feature_category: :incident_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:environment) { create(:environment, project: project) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  shared_examples 'unprivileged' do
    before do
      project.add_developer(user)
    end

    it 'returns not_found' do
      make_request

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'project non-specific environment' do |status|
    let(:other) { create(:environment) }

    it "returns #{status}" do
      make_request(environment_id: other)

      expect(response).to have_gitlab_http_status(status)
    end

    if status == :ok
      it 'returns no prometheus alerts' do
        make_request(environment_id: other)

        expect(json_response).to be_empty
      end
    end
  end

  describe 'POST #notify' do
    let(:alert_1) { build(:alert_management_alert, :prometheus, project: project) }
    let(:alert_2) { build(:alert_management_alert, :prometheus, project: project) }
    let(:service_response) { ServiceResponse.success(http_status: :created) }
    let(:notify_service) { instance_double(Projects::Prometheus::Alerts::NotifyService, execute: service_response) }

    before do
      sign_out(user)

      expect(Projects::Prometheus::Alerts::NotifyService)
        .to receive(:new)
        .with(project, duck_type(:permitted?))
        .and_return(notify_service)
    end

    it 'returns created if notification succeeds' do
      expect(notify_service).to receive(:execute).and_return(service_response)

      post :notify, params: project_params, session: { as: :json }

      expect(response).to have_gitlab_http_status(:created)
    end

    it 'returns unprocessable entity if notification fails' do
      expect(notify_service).to receive(:execute).and_return(
        ServiceResponse.error(message: 'Unprocessable Entity', http_status: :unprocessable_entity)
      )

      post :notify, params: project_params, session: { as: :json }

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end

    context 'bearer token' do
      context 'when set' do
        it 'extracts bearer token' do
          request.headers['HTTP_AUTHORIZATION'] = 'Bearer some token'

          expect(notify_service).to receive(:execute).with('some token')

          post :notify, params: project_params, as: :json
        end

        it 'pass nil if cannot extract a non-bearer token' do
          request.headers['HTTP_AUTHORIZATION'] = 'some token'

          expect(notify_service).to receive(:execute).with(nil)

          post :notify, params: project_params, as: :json
        end
      end

      context 'when missing' do
        it 'passes nil' do
          expect(notify_service).to receive(:execute).with(nil)

          post :notify, params: project_params, as: :json
        end
      end
    end
  end

  def project_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace, project_id: project)
  end
end
