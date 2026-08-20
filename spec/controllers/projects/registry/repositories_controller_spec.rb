# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Registry::RepositoriesController, feature_category: :container_registry do
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:user) { create(:user, developer_of: project) }

  let(:format) { :html }

  before do
    sign_in(user)
    stub_container_registry_config(enabled: true)
    stub_container_registry_info
  end

  shared_examples 'renders 200 for html and 404 for json' do
    it 'successfully renders container repositories', :snowplow do
      expect(go_to_index_response).to have_gitlab_http_status(:ok)
      # event tracked in GraphQL API: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/44926
      expect_no_snowplow_event
    end

    context 'with format "json"' do
      let(:format) { :json }

      it 'returns 404 for request in json format' do
        expect(go_to_index_response).to have_gitlab_http_status(:not_found)
      end
    end

    [ContainerRegistry::Path::InvalidRegistryPathError, Faraday::Error].each do |error_class|
      context "when there is a #{error_class}" do
        it 'displays a connection error message' do
          expect(::ContainerRegistry::Client).to receive(:registry_info).and_raise(error_class, nil, nil)

          expect(go_to_index_response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  shared_examples 'renders a list of repositories' do
    context 'when root container repository exists' do
      before do
        create(:container_repository, :root, project: project)
      end

      it 'does not create root container repository' do
        expect { go_to_index_response }.not_to change { ContainerRepository.all.count }
      end
    end

    context 'when root container repository is not created' do
      context 'when there are tags for this repository' do
        before do
          stub_container_registry_tags(repository: :any, tags: %w[rc1 latest])
        end

        it 'creates a root container repository' do
          expect { go_to_index_response }.to change { ContainerRepository.all.count }.by(1)
          expect(ContainerRepository.first).to have_attributes(project: project, name: '')
        end

        it_behaves_like 'renders 200 for html and 404 for json'
      end

      context 'when there are no tags for this repository' do
        before do
          stub_container_registry_tags(repository: :any, tags: [])
        end

        it 'does not ensure root container repository' do
          expect { go_to_index_response }.not_to change { ContainerRepository.all.count }
        end
      end
    end
  end

  describe 'GET #index' do
    let(:params) { { namespace_id: project.namespace, project_id: project } }

    subject(:go_to_index_response) do
      get :index, params: params, format: format

      response
    end

    context 'when user has access to registry' do
      it_behaves_like 'renders a list of repositories'
    end

    context 'when user does not have access to registry' do
      let_it_be(:user) { create(:user) }

      it 'responds with 404' do
        expect(go_to_index_response).to have_gitlab_http_status(:not_found)
      end

      it 'does not ensure root container repository' do
        expect { go_to_index_response }.not_to change { ContainerRepository.all.count }
      end
    end
  end

  describe 'GET #show' do
    let_it_be(:container_repository) { create(:container_repository, project: project) }

    let(:params) { { namespace_id: project.namespace, project_id: project, id: container_repository } }

    subject(:go_to_show_response) do
      get :show, params: params, format: format

      response
    end

    context 'when user has access to registry' do
      it 'successfully renders the container repository index page', :snowplow do
        expect(go_to_show_response).to have_gitlab_http_status(:ok)
        # event tracked in GraphQL API: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/44926
        expect_no_snowplow_event
      end
    end
  end

  describe 'DELETE #destroy' do
    let_it_be_with_reload(:repository) { create(:container_repository, :root, project: project) }

    let(:format) { :json }
    let(:params) { { namespace_id: project.namespace, project_id: project, id: repository } }

    subject(:delete_repository_response) do
      delete :destroy, params: params, format: format

      response
    end

    before do
      stub_container_registry_tags(repository: :any, tags: [])
    end

    it 'marks the repository as delete_scheduled' do
      expect { delete_repository_response }
        .to change { repository.reload.status }.from(nil).to('delete_scheduled')

      expect(response).to have_gitlab_http_status(:no_content)
    end

    it 'tracks the event', :snowplow do
      delete_repository_response

      expect_snowplow_event(category: anything, action: 'delete_repository')
    end
  end
end
