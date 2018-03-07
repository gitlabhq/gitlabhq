require 'spec_helper'

describe Projects::Registry::RepositoriesController do
  let(:user)    { create(:user) }
  let(:project) { create(:project, :private) }

  before do
    sign_in(user)
    stub_container_registry_config(enabled: true)
  end

  context 'when user has access to registry' do
    before do
      project.add_developer(user)
    end

    describe 'GET index' do
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
            stub_container_registry_tags(repository: project.full_path,
                                         tags: %w[rc1 latest])
          end

          it 'successfully renders container repositories' do
            go_to_index

            expect(response).to have_gitlab_http_status(:ok)
          end

          it 'creates a root container repository' do
            expect { go_to_index }.to change { ContainerRepository.all.count }.by(1)
            expect(ContainerRepository.first).to be_root_repository
          end

          it 'json has a list of projects' do
            go_to_index(format: :json)

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('registry/repositories')
          end
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

    describe 'DELETE destroy' do
      context 'when root container repository exists' do
        let!(:repository) do
          create(:container_repository, :root, project: project)
        end

        before do
          stub_container_registry_tags(repository: :any, tags: [])
        end

        it 'deletes a repository' do
          expect { delete_repository(repository) }.to change { ContainerRepository.all.count }.by(-1)

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end
    end
  end

  context 'when user does not have access to registry' do
    describe 'GET index' do
      it 'responds with 404' do
        go_to_index

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'does not ensure root container repository' do
        expect { go_to_index }.not_to change { ContainerRepository.all.count }
      end
    end
  end

  def go_to_index(format: :html)
    get :index, namespace_id: project.namespace,
                project_id: project,
                format: format
  end

  def delete_repository(repository)
    delete :destroy, namespace_id: project.namespace,
                     project_id: project,
                     id: repository,
                     format: :json
  end
end
