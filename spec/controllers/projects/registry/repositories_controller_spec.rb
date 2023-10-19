# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Registry::RepositoriesController, feature_category: :container_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private) }

  before do
    sign_in(user)
    stub_container_registry_config(enabled: true)
    stub_container_registry_info
  end

  context 'when user has access to registry' do
    before do
      project.add_developer(user)
    end

    shared_examples 'renders 200 for html and 404 for json' do
      it 'successfully renders container repositories', :snowplow do
        go_to_index

        expect(response).to have_gitlab_http_status(:ok)
        # event tracked in GraphQL API: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/44926
        expect_no_snowplow_event
      end

      it 'returns 404 for request in json format' do
        go_to_index(format: :json)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      [ContainerRegistry::Path::InvalidRegistryPathError, Faraday::Error].each do |error_class|
        context "when there is a #{error_class}" do
          it 'displays a connection error message' do
            expect(::ContainerRegistry::Client).to receive(:registry_info).and_raise(error_class, nil, nil)

            go_to_index

            expect(response).to have_gitlab_http_status(:ok)
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
          expect { go_to_index }.not_to change { ContainerRepository.all.count }
        end
      end

      context 'when root container repository is not created' do
        context 'when there are tags for this repository' do
          before do
            stub_container_registry_tags(repository: :any, tags: %w[rc1 latest])
          end

          it 'creates a root container repository' do
            expect { go_to_index }.to change { ContainerRepository.all.count }.by(1)
            expect(ContainerRepository.first).to be_root_repository
          end

          it_behaves_like 'renders 200 for html and 404 for json'
        end

        context 'when there are no tags for this repository' do
          before do
            stub_container_registry_tags(repository: :any, tags: [])
          end

          it 'does not ensure root container repository' do
            expect { go_to_index }.not_to change { ContainerRepository.all.count }
          end

          it_behaves_like 'renders 200 for html and 404 for json'
        end
      end
    end

    describe 'GET #index' do
      it_behaves_like 'renders a list of repositories'
    end

    describe 'GET #show' do
      it_behaves_like 'renders a list of repositories'
    end

    describe 'DELETE #destroy' do
      context 'when root container repository exists' do
        let!(:repository) do
          create(:container_repository, :root, project: project)
        end

        before do
          stub_container_registry_tags(repository: :any, tags: [])
        end

        it 'marks the repository as delete_scheduled' do
          expect { delete_repository(repository) }
            .to change { repository.reload.status }.from(nil).to('delete_scheduled')

          expect(repository.reload).to be_delete_scheduled
          expect(response).to have_gitlab_http_status(:no_content)
        end

        it 'tracks the event', :snowplow do
          delete_repository(repository)

          expect_snowplow_event(category: anything, action: 'delete_repository')
        end
      end
    end
  end

  context 'when user does not have access to registry' do
    describe 'GET #index' do
      it 'responds with 404' do
        go_to_index

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'does not ensure root container repository' do
        expect { go_to_index }.not_to change { ContainerRepository.all.count }
      end
    end
  end

  def go_to_index(format: :html, params: {})
    get :index, params: params.merge({ namespace_id: project.namespace, project_id: project }), format: format
  end

  def delete_repository(repository)
    delete :destroy, params: {
      namespace_id: project.namespace, project_id: project, id: repository
    }, format: :json
  end
end
