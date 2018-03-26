require 'spec_helper'

describe SearchController do
  include ExternalAuthorizationServiceHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }
  let(:note) { create(:note_on_issue, project: project) }

  before do
    sign_in(user)
  end

  context 'with external authorization service enabled' do
    before do
      enable_external_authorization_service_check
    end

    describe 'GET #show' do
      it 'renders a 404 when no project is given' do
        get :show, scope: 'notes', search: note.note

        expect(response).to have_gitlab_http_status(404)
      end

      it 'renders a 200 when a project was set' do
        get :show, project_id: project.id, scope: 'notes', search: note.note

        expect(response).to have_gitlab_http_status(200)
      end
    end

    describe 'GET #autocomplete' do
      it 'renders a 404 when no project is given' do
        get :autocomplete, term: 'hello'

        expect(response).to have_gitlab_http_status(404)
      end

      it 'renders a 200 when a project was set' do
        get :autocomplete, project_id: project.id, term: 'hello'

        expect(response).to have_gitlab_http_status(200)
      end
    end
  end
end
