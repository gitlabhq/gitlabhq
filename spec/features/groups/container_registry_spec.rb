# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Container Registry', :js do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: group) }

  let(:container_repository) do
    create(:container_repository, name: 'my/image')
  end

  before do
    group.add_owner(user)
    sign_in(user)
    stub_container_registry_config(enabled: true)
    stub_container_registry_tags(repository: :any, tags: [])
  end

  it 'has a page title set' do
    visit_container_registry

    expect(page).to have_title _('Container Registry')
  end

  it 'sidebar menu is open' do
    visit_container_registry

    sidebar = find('.nav-sidebar')
    expect(sidebar).to have_link _('Container Registry')
  end

  context 'when there are no image repositories' do
    it 'list page has no container title' do
      visit_container_registry

      expect(page).to have_content _('There are no container images available in this group')
    end
  end

  context 'when there are image repositories' do
    before do
      stub_container_registry_tags(repository: %r{my/image}, tags: %w[latest], with_manifest: true)
      project.container_repositories << container_repository
    end

    it 'list page has a list of images' do
      visit_container_registry

      expect(page).to have_content 'my/image'
    end

    it 'navigates to repo details' do
      visit_container_registry_details('my/image')

      expect(page).to have_content 'latest'
    end

    describe 'image repo details' do
      before do
        visit_container_registry_details 'my/image'
      end

      it 'shows the details breadcrumb' do
        expect(find('.breadcrumbs')).to have_link 'my/image'
      end

      it 'shows the image title' do
        expect(page).to have_content 'my/image'
      end

      it 'shows the image tags' do
        expect(page).to have_content 'Image tags'
        first_tag = first('[data-testid="name"]')
        expect(first_tag).to have_content 'latest'
      end

      it 'user removes a specific tag from container repository' do
        service = double('service')
        expect(service).to receive(:execute).with(container_repository) { { status: :success } }
        expect(Projects::ContainerRepository::DeleteTagsService).to receive(:new).with(container_repository.project, user, tags: ['latest']) { service }

        first('[data-testid="single-delete-button"]').click
        expect(find('.modal .modal-title')).to have_content _('Remove tag')
        find('.modal .modal-footer .btn-danger').click
      end
    end
  end

  context 'when an image has the same name as the subgroup' do
    before do
      stub_container_registry_tags(tags: %w[latest], with_manifest: true)
      project.container_repositories <<  create(:container_repository, name: group.name)
      visit_container_registry
    end

    it 'details page loads properly' do
      find('a[data-testid="details-link"]').click

      expect(page).to have_content 'latest'
    end
  end

  def visit_container_registry
    visit group_container_registries_path(group)
  end

  def visit_container_registry_details(name)
    visit_container_registry
    click_link(name)
  end
end
