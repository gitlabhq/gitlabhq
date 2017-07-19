require 'spec_helper'

describe Projects::Registry::TagsController do
  let(:user)    { create(:user) }
  let(:project) { create(:empty_project, :private) }

  before do
    sign_in(user)
    stub_container_registry_config(enabled: true)
  end

  context 'when user has access to registry' do
    before do
      project.add_developer(user)
    end

    describe 'POST destroy' do
      context 'when there is matching tag present' do
        before do
          stub_container_registry_tags(repository: /image/, tags: %w[rc1 test.])
        end

        let(:repository) do
          create(:container_repository, name: 'image', project: project)
        end

        it 'makes it possible to delete regular tag' do
          expect_any_instance_of(ContainerRegistry::Tag).to receive(:delete)

          destroy_tag('rc1')
        end

        it 'makes it possible to delete a tag that ends with a dot' do
          expect_any_instance_of(ContainerRegistry::Tag).to receive(:delete)

          destroy_tag('test.')
        end
      end
    end
  end

  def destroy_tag(name)
    post :destroy, namespace_id: project.namespace,
                   project_id: project,
                   repository_id: repository,
                   id: name
  end
end
