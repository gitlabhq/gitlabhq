# frozen_string_literal: true

require 'spec_helper'

describe 'Container Registry', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  let(:container_repository) do
    create(:container_repository, name: 'my/image')
  end

  before do
    sign_in(user)
    project.add_developer(user)
    stub_container_registry_config(enabled: true)
    stub_container_registry_tags(repository: :any, tags: [])
  end

  context 'when there are no image repositories' do
    it 'user visits container registry main page' do
      visit_container_registry

      expect(page).to have_content 'no container images'
    end
  end

  context 'when there are image repositories' do
    before do
      stub_container_registry_tags(repository: %r{my/image}, tags: %w[latest], with_manifest: true)
      project.container_repositories << container_repository
    end

    it 'user wants to see multi-level container repository' do
      visit_container_registry

      expect(page).to have_content('my/image')
    end

    it 'user removes entire container repository' do
      visit_container_registry

      expect_any_instance_of(ContainerRepository).to receive(:delete_tags!).and_return(true)

      click_on(class: 'js-remove-repo')
      expect(find('.modal .modal-title')).to have_content 'Remove repository'
      find('.modal .modal-footer .btn-danger').click
    end

    it 'user removes a specific tag from container repository' do
      visit_container_registry

      find('.js-toggle-repo').click
      wait_for_requests

      expect_any_instance_of(ContainerRegistry::Tag).to receive(:delete).and_return(true)

      click_on(class: 'js-delete-registry-row', visible: false)
      expect(find('.modal .modal-title')).to have_content 'Remove image'
      find('.modal .modal-footer .btn-danger').click
    end
  end

  def visit_container_registry
    visit project_container_registry_index_path(project)
  end
end
