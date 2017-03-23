require 'spec_helper'

describe "Container Registry" do
  let(:project) { create(:empty_project) }
  let(:registry) { project.container_registry }
  let(:tag_name) { 'latest' }
  let(:tags) { [tag_name] }
  let(:container_image) { create(:container_image) }
  let(:image_name) { container_image.name }

  before do
    login_as(:user)
    project.team << [@user, :developer]
    stub_container_registry_config(enabled: true)
    stub_container_registry_tags(*tags)
    project.container_images << container_image unless container_image.nil?
    allow(Auth::ContainerRegistryAuthenticationService).to receive(:full_access_token).and_return('token')
  end

  describe 'GET /:project/container_registry' do
    before do
      visit namespace_project_container_registry_index_path(project.namespace, project)
    end

    context 'when no images' do
      let(:container_image) { }

      it { expect(page).to have_content('No container images in Container Registry for this project') }
    end

    context 'when there are images' do
      it { expect(page).to have_content(image_name) }
    end
  end

  describe 'DELETE /:project/container_registry/:image_id' do
    before do
      visit namespace_project_container_registry_index_path(project.namespace, project)
    end

    it do
      expect_any_instance_of(ContainerRepository).to receive(:delete_tags).and_return(true)

      click_on 'Remove image'
    end
  end

  describe 'DELETE /:project/container_registry/tag' do
    before do
      visit namespace_project_container_registry_index_path(project.namespace, project)
    end

    it do
      expect_any_instance_of(::ContainerRegistry::Tag).to receive(:delete).and_return(true)

      click_on 'Remove tag'
    end
  end
end
