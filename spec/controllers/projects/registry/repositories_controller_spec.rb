# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Registry::RepositoriesController do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private) }

  before do
    sign_in(user)
    stub_container_registry_config(enabled: true)
  end

  context 'when user has access to registry' do
    before do
      project.add_developer(user)
    end

    shared_examples 'with name parameter' do
      let_it_be(:repo) { create(:container_repository, project: project, name: 'my_searched_image') }
      let_it_be(:another_repo) { create(:container_repository, project: project, name: 'bar') }

      it 'returns the searched repo' do
        go_to_index(format: :json, params: { name: 'my_searched_image' })

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.length).to eq 1
        expect(json_response.first).to include(
          'id' => repo.id,
          'name' => repo.name
        )
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
            stub_container_registry_tags(repository: :any,
                                         tags: %w[rc1 latest])
          end

          it 'successfully renders container repositories', :snowplow do
            go_to_index

            expect_no_snowplow_event
            expect(response).to have_gitlab_http_status(:ok)
          end

          it 'tracks the event', :snowplow do
            go_to_index(format: :json)

            expect_snowplow_event(category: anything, action: 'list_repositories')
          end

          it 'creates a root container repository' do
            expect { go_to_index }.to change { ContainerRepository.all.count }.by(1)
            expect(ContainerRepository.first).to be_root_repository
          end

          it 'json has a list of projects' do
            go_to_index(format: :json)

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('registry/repositories')
            expect(response).to include_pagination_headers
          end

          it_behaves_like 'with name parameter'
        end

        context 'when there are no tags for this repository' do
          before do
            stub_container_registry_tags(repository: :any, tags: [])
          end

          it 'successfully renders container repositories' do
            go_to_index

            expect(response).to have_gitlab_http_status(:ok)
          end

          it 'does not ensure root container repository' do
            expect { go_to_index }.not_to change { ContainerRepository.all.count }
          end

          it 'responds with json if asked' do
            go_to_index(format: :json)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to be_kind_of(Array)
          end
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

        it 'schedules a job to delete a repository' do
          expect(DeleteContainerRepositoryWorker).to receive(:perform_async).with(user.id, repository.id)

          delete_repository(repository)

          expect(repository.reload).to be_delete_scheduled
          expect(response).to have_gitlab_http_status(:no_content)
        end

        it 'tracks the event', :snowplow do
          allow(DeleteContainerRepositoryWorker).to receive(:perform_async).with(user.id, repository.id)

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

  def go_to_index(format: :html, params: {} )
    get :index, params: params.merge({
                  namespace_id: project.namespace,
                  project_id: project
                }),
                format: format
  end

  def delete_repository(repository)
    delete :destroy, params: {
                       namespace_id: project.namespace,
                       project_id: project,
                       id: repository
                     },
                     format: :json
  end
end
