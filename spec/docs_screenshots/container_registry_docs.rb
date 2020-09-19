# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Container Registry', :js do
  include DocsScreenshotHelpers

  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: group) }

  before do
    page.driver.browser.manage.window.resize_to(1366, 1024)

    group.add_owner(user)
    sign_in(user)

    stub_container_registry_config(enabled: true)
    stub_container_registry_tags(repository: :any, tags: [])
  end

  context 'expiration policy settings' do
    it 'user/packages/container_registry/img/expiration_policy_form' do
      visit project_settings_ci_cd_path(project)
      screenshot_area = find('#js-registry-policies')
      scroll_to screenshot_area
      expect(screenshot_area).to have_content 'Expiration interval'
      set_crop_data(screenshot_area, 20)
    end
  end

  context 'project container_registry' do
    it 'user/packages/container_registry/img/project_empty_page' do
      visit_project_container_registry

      expect(page).to have_content _('There are no container images stored for this project')
    end

    context 'with a list of repositories' do
      before do
        stub_container_registry_tags(repository: %r{my/image}, tags: %w[latest], with_manifest: true)
        create_list(:container_repository, 12, project: project)
      end

      it 'user/packages/container_registry/img/project_image_repositories_list' do
        visit_project_container_registry

        expect(page).to have_content 'Image Repositories'
      end

      it 'user/packages/container_registry/img/project_image_repositories_list_with_commands_open' do
        visit_project_container_registry

        click_on 'CLI Commands'
      end
    end
  end

  context 'group container_registry' do
    it 'user/packages/container_registry/img/group_empty_page' do
      visit_group_container_registry

      expect(page).to have_content 'There are no container images available in this group'
    end

    context 'with a list of repositories' do
      before do
        stub_container_registry_tags(repository: %r{my/image}, tags: %w[latest], with_manifest: true)
        create_list(:container_repository, 12, project: project)
      end

      it 'user/packages/container_registry/img/group_image_repositories_list' do
        visit_group_container_registry

        expect(page).to have_content 'Image Repositories'
      end
    end
  end

  def visit_project_container_registry
    visit project_container_registry_index_path(project)
  end

  def visit_group_container_registry
    visit group_container_registries_path(group)
  end
end
