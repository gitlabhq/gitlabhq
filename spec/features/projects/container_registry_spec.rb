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

  it 'has a page title set' do
    visit_container_registry

    expect(page).to have_title _('Container Registry')
  end

  context 'when there are no image repositories' do
    it 'list page has no container title' do
      visit_container_registry

      expect(page).to have_content _('There are no container images stored for this project')
    end

    it 'list page has cli commands' do
      visit_container_registry

      expect(page).to have_content _('CLI Commands')
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

    it 'user removes entire container repository', :sidekiq_might_not_need_inline do
      visit_container_registry

      expect_any_instance_of(ContainerRepository).to receive(:delete_tags!).and_return(true)

      find('[title="Remove repository"]').click
      expect(find('.modal .modal-title')).to have_content _('Remove repository')
      find('.modal .modal-footer .btn-danger').click
    end

    it 'navigates to repo details' do
      visit_container_registry_details('my/image')

      expect(page).to have_content 'latest'
    end

    describe 'image repo details' do
      before do
        stub_container_registry_tags(repository: %r{my/image}, tags: ('1'..'20').to_a, with_manifest: true)
        visit_container_registry_details 'my/image'
      end

      it 'shows the details breadcrumb' do
        expect(find('.breadcrumbs')).to have_link 'my/image'
      end

      it 'shows the image title' do
        expect(page).to have_content 'my/image tags'
      end

      it 'user removes a specific tag from container repository' do
        service = double('service')
        expect(service).to receive(:execute).with(container_repository) { { status: :success } }
        expect(Projects::ContainerRepository::DeleteTagsService).to receive(:new).with(container_repository.project, user, tags: ['1']) { service }

        first('[data-testid="singleDeleteButton"]').click
        expect(find('.modal .modal-title')).to have_content _('Remove tag')
        find('.modal .modal-footer .btn-danger').click
      end

      it('pagination navigate to the second page') do
        visit_second_page
        expect(page).to have_content '20'
      end
    end
  end

  context 'when there are more than 10 images' do
    before do
      create_list(:container_repository, 12, project: project)
      project.container_repositories << container_repository
      visit_container_registry
    end

    it 'shows pagination' do
      expect(page).to have_css '.gl-pagination'
    end

    it 'pagination goes to second page' do
      visit_second_page
      expect(page).to have_content 'my/image'
    end

    it 'pagination is preserved after navigating back from details' do
      visit_second_page
      click_link 'my/image'
      breadcrumb = find '.breadcrumbs'
      breadcrumb.click_link 'Container Registry'
      expect(page).to have_content 'my/image'
    end
  end

  def visit_container_registry
    visit project_container_registry_index_path(project)
  end

  def visit_container_registry_details(name)
    visit_container_registry
    click_link name
  end

  def visit_second_page
    pagination = find '.gl-pagination'
    pagination.click_link '2'
  end
end
