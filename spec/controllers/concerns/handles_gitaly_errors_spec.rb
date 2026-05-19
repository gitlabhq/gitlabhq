# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HandlesGitalyErrors, feature_category: :source_code_management do
  let(:gitaly_errors) do
    {
      index: Gitlab::Git::CommandError,
      show: Gitlab::Git::CommandTimedOut,
      grpc_unavailable: GRPC::Unavailable,
      grpc_deadline: GRPC::DeadlineExceeded,
      grpc_resource_exhausted: GRPC::ResourceExhausted,
      resource_exhausted_error: Gitlab::Git::ResourceExhaustedError
    }
  end

  controller(ApplicationController) do
    include HandlesGitalyErrors

    skip_before_action :authenticate_user!

    def index
      raise Gitlab::Git::CommandError, 'Gitaly unavailable'
    end

    def show
      raise Gitlab::Git::CommandTimedOut, 'Gitaly timed out'
    end

    def grpc_unavailable
      raise GRPC::Unavailable, 'GRPC unavailable'
    end

    def grpc_deadline
      raise GRPC::DeadlineExceeded, 'GRPC deadline exceeded'
    end

    def grpc_resource_exhausted
      raise GRPC::ResourceExhausted, 'GRPC resource exhausted'
    end

    def resource_exhausted_error
      raise Gitlab::Git::ResourceExhaustedError, 'Resource exhausted'
    end
  end

  before do
    routes.draw do
      get 'index' => 'anonymous#index'
      get 'show' => 'anonymous#show'
      get 'grpc_unavailable' => 'anonymous#grpc_unavailable'
      get 'grpc_deadline' => 'anonymous#grpc_deadline'
      get 'grpc_resource_exhausted' => 'anonymous#grpc_resource_exhausted'
      get 'resource_exhausted_error' => 'anonymous#resource_exhausted_error'
    end
  end

  describe '#handle_gitaly_error' do
    where(:action, :error_class) do
      [
        [:index, Gitlab::Git::CommandError],
        [:show, Gitlab::Git::CommandTimedOut],
        [:grpc_unavailable, GRPC::Unavailable],
        [:grpc_deadline, GRPC::DeadlineExceeded],
        [:grpc_resource_exhausted, GRPC::ResourceExhausted],
        [:resource_exhausted_error, Gitlab::Git::ResourceExhaustedError]
      ]
    end

    with_them do
      it 'returns 503 status' do
        get action, format: :json

        expect(response).to have_gitlab_http_status(:service_unavailable)
      end

      it 'tracks the exception' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(error_class))

        get action, format: :json
      end
    end

    context 'with JSON format' do
      context 'on GitLab.com' do
        before do
          allow(Gitlab).to receive(:com?).and_return(true)
        end

        it 'returns SaaS error message in JSON' do
          get :index, format: :json

          expect(json_response['error']).to eq(
            'GitLab is currently unable to handle this request. Please try again later.'
          )
        end
      end

      context 'on self-managed' do
        before do
          allow(Gitlab).to receive(:com?).and_return(false)
        end

        it 'returns self-managed error message in JSON' do
          get :index, format: :json

          expect(json_response['error']).to eq(
            'The git server, Gitaly, is not available at this time. Please contact your administrator.'
          )
        end
      end
    end

    context 'with plain text format' do
      it 'returns 503 status' do
        get :index, format: :text

        expect(response).to have_gitlab_http_status(:service_unavailable)
      end

      context 'on GitLab.com' do
        before do
          allow(Gitlab).to receive(:com?).and_return(true)
        end

        it 'returns SaaS error message as plain text' do
          get :index, format: :text

          expect(response.body).to eq(
            'GitLab is currently unable to handle this request. Please try again later.'
          )
        end
      end

      context 'on self-managed' do
        before do
          allow(Gitlab).to receive(:com?).and_return(false)
        end

        it 'returns self-managed error message as plain text' do
          get :index, format: :text

          expect(response.body).to eq(
            'The git server, Gitaly, is not available at this time. Please contact your administrator.'
          )
        end
      end
    end

    context 'with HTML format' do
      before do
        allow(controller).to receive(:render).and_call_original
        allow(controller).to receive(:render).with(action: 'index', status: :service_unavailable)
      end

      it 'tracks the exception' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(Gitlab::Git::CommandError))

        get :index, format: :html
      end

      it 'renders the action template with 503 status' do
        expect(controller).to receive(:render).with(action: 'index', status: :service_unavailable)

        get :index, format: :html
      end
    end

    context 'with Atom format' do
      before do
        allow(controller).to receive(:render).and_call_original
        allow(controller).to receive(:render).with(action: 'index', layout: 'xml', status: :service_unavailable)
      end

      it 'renders the action template with xml layout and 503 status' do
        expect(controller).to receive(:render).with(action: 'index', layout: 'xml', status: :service_unavailable)

        get :index, format: :atom
      end
    end
  end

  describe '#gitaly_unavailable_message' do
    context 'on GitLab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'returns the SaaS message' do
        expect(controller.send(:gitaly_unavailable_message)).to eq(
          'GitLab is currently unable to handle this request. Please try again later.'
        )
      end
    end

    context 'on self-managed' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
      end

      it 'returns the self-managed message' do
        expect(controller.send(:gitaly_unavailable_message)).to eq(
          'The git server, Gitaly, is not available at this time. Please contact your administrator.'
        )
      end
    end
  end
end
