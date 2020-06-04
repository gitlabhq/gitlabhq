# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectUnauthorized do
  include ExternalAuthorizationServiceHelpers
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  render_views

  describe '.on_routable_not_found' do
    controller(::Projects::ApplicationController) do
      def show
        head :ok
      end
    end

    let(:project) { create(:project) }

    before do
      project.add_developer(user)
    end

    it 'renders a 200 when the service allows access to the project' do
      external_service_allow_access(user, project)

      get :show, params: { namespace_id: project.namespace.to_param, id: project.to_param }

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'renders a 403 when the service denies access to the project' do
      external_service_deny_access(user, project)

      get :show, params: { namespace_id: project.namespace.to_param, id: project.to_param }

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(response.body).to match("External authorization denied access to this project")
    end

    it 'renders a 404 when the user cannot see the project at all' do
      other_project = create(:project, :private)

      get :show, params: { namespace_id: other_project.namespace.to_param, id: other_project.to_param }

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
