# frozen_string_literal: true

require 'spec_helper'

# Other methods in this concern are tested indirectly via the controller specs for
# Groups::DependencyProxy::ApplicationController and VirtualRegistries::ContainerController.
# valid_service_type? is tested here directly because its default implementation
# (returning false) is never reachable through those controllers, which all override it.
RSpec.describe JwtAuthenticatable, feature_category: :virtual_registry do
  include DependencyProxyHelpers

  controller(ApplicationController) do
    include JwtAuthenticatable

    def index
      head :ok
    end
  end

  before do
    routes.draw { get 'index' => 'anonymous#index' }
  end

  describe '#valid_service_type?' do
    let_it_be(:user) { create(:user) }
    let(:jwt) { build_jwt(user) }

    before do
      request.headers['HTTP_AUTHORIZATION'] = "Bearer #{jwt.encoded}"
    end

    context 'when not overridden by the including controller' do
      it 'rejects all requests regardless of service_type' do
        get :index

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
