require 'spec_helper'

describe EE::Projects::ApplicationController do
  include ExternalAuthorizationServiceHelpers
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  render_views

  describe '#handle_not_found_or_authorized' do
    controller(::Projects::ApplicationController) do
      def show
        render nothing: true
      end
    end

    let(:project) { create(:project) }

    before do
      project.add_developer(user)
    end

    it 'renders a 200 when the service allows access to the project' do
      external_service_allow_access(user, project)

      get :show, namespace_id: project.namespace.to_param, id: project.to_param

      expect(response).to have_gitlab_http_status(200)
    end

    it 'renders a 403 when the service denies access to the project' do
      external_service_deny_access(user, project)

      get :show, namespace_id: project.namespace.to_param, id: project.to_param

      expect(response).to have_gitlab_http_status(403)
      expect(response.body).to match("External authorization denied access to this project")
    end

    it 'renders a 404 when the user cannot see the project at all' do
      other_project = create(:project, :private)

      get :show, namespace_id: other_project.namespace.to_param, id: other_project.to_param

      expect(response).to have_gitlab_http_status(404)
    end
  end
end
