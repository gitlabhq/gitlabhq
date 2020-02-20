# frozen_string_literal: true

require 'spec_helper'

describe Groups::Registry::RepositoriesController do
  let_it_be(:user)  { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:group, reload: true) { create(:group) }

  before do
    stub_container_registry_config(enabled: true)
    group.add_owner(user)
    group.add_guest(guest)
    sign_in(user)
  end

  shared_examples 'renders a list of repositories' do
    context 'when container registry is enabled' do
      it 'show index page' do
        expect(Gitlab::Tracking).not_to receive(:event)

        get :index, params: {
            group_id: group
        }

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'has the correct response schema' do
        get :index, params: {
          group_id: group,
          format: :json
        }

        expect(response).to match_response_schema('registry/repositories')
        expect(response).to include_pagination_headers
      end

      it 'returns a list of projects for json format' do
        project = create(:project, group: group)
        repo = create(:container_repository, project: project)

        get :index, params: {
          group_id: group,
          format: :json
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_kind_of(Array)
        expect(json_response.first).to include(
          'id' => repo.id,
          'name' => repo.name
        )
      end

      it 'tracks the event' do
        expect(Gitlab::Tracking).to receive(:event).with(anything, 'list_repositories', {})

        get :index, params: {
          group_id: group,
          format: :json
        }
      end
    end

    context 'container registry is disabled' do
      before do
        stub_container_registry_config(enabled: false)
      end

      it 'renders not found' do
        get :index, params: {
            group_id: group
        }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'user do not have acces to container registry' do
      before do
        sign_out(user)
        sign_in(guest)
      end

      it 'renders not found' do
        get :index, params: {
          group_id: group
        }
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with :vue_container_registry_explorer feature flag disabled' do
      before do
        stub_feature_flags(vue_container_registry_explorer: false)
      end

      it 'has the correct response schema' do
        get :index, params: {
          group_id: group,
          format: :json
        }

        expect(response).to match_response_schema('registry/repositories')
        expect(response).not_to include_pagination_headers
      end
    end
  end

  context 'GET #index' do
    it_behaves_like 'renders a list of repositories'
  end

  context 'GET #show' do
    it_behaves_like 'renders a list of repositories'
  end
end
