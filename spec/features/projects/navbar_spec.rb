# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project navbar' do
  include NavbarStructureHelper
  include WaitForRequests

  include_context 'project navbar structure'

  let_it_be(:project) { create(:project, :repository) }

  let(:user) { project.owner }

  before do
    sign_in(user)
  end

  context 'when sidebar refactor feature flag is disabled' do
    before do
      stub_feature_flags(sidebar_refactor: false)
      insert_package_nav(_('Operations'))
      insert_infrastructure_registry_nav

      insert_after_sub_nav_item(
        _('Boards'),
        within: _('Issues'),
        new_sub_nav_item_name: _('Labels')
      )

      insert_after_nav_item(
        _('Snippets'),
        new_nav_item: {
          nav_item: _('Members'),
          nav_sub_items: []
        }
      )

      stub_config(registry: { enabled: false })
    end

    it_behaves_like 'verified navigation bar' do
      before do
        visit project_path(project)
      end
    end

    context 'when value stream is available' do
      before do
        visit project_path(project)
      end

      it 'redirects to value stream when Analytics item is clicked' do
        page.within('.sidebar-top-level-items') do
          find('.shortcuts-analytics').click
        end

        wait_for_requests

        expect(page).to have_current_path(project_cycle_analytics_path(project))
      end
    end

    context 'when pages are available' do
      before do
        stub_config(pages: { enabled: true })

        insert_after_sub_nav_item(
          _('Operations'),
          within: _('Settings'),
          new_sub_nav_item_name: _('Pages')
        )

        visit project_path(project)
      end

      it_behaves_like 'verified navigation bar'
    end

    context 'when container registry is available' do
      before do
        stub_config(registry: { enabled: true })

        insert_container_nav

        visit project_path(project)
      end

      it_behaves_like 'verified navigation bar'
    end
  end

  context 'when sidebar refactor feature flag is enabled' do
    let(:monitor_nav_item) do
      {
        nav_item: _('Monitor'),
        nav_sub_items: monitor_menu_items
      }
    end

    let(:monitor_menu_items) do
      [
        _('Metrics'),
        _('Logs'),
        _('Tracing'),
        _('Error Tracking'),
        _('Alerts'),
        _('Incidents'),
        _('Product Analytics')
      ]
    end

    let(:project_information_nav_item) do
      {
        nav_item: _('Project information'),
        nav_sub_items: [
          _('Activity'),
          _('Labels'),
          _('Members')
        ]
      }
    end

    let(:settings_menu_items) do
      [
        _('General'),
        _('Integrations'),
        _('Webhooks'),
        _('Access Tokens'),
        _('Repository'),
        _('CI/CD'),
        _('Monitor')
      ]
    end

    before do
      stub_feature_flags(sidebar_refactor: true)
      stub_config(registry: { enabled: true })
      insert_package_nav(_('Monitor'))
      insert_infrastructure_registry_nav
      insert_container_nav

      insert_after_sub_nav_item(
        _('Monitor'),
        within: _('Settings'),
        new_sub_nav_item_name: _('Packages & Registries')
      )

      insert_after_nav_item(
        _('Monitor'),
        new_nav_item: {
          nav_item: _('Infrastructure'),
          nav_sub_items: [
            _('Kubernetes clusters'),
            _('Serverless platform'),
            _('Terraform')
          ]
        }
      )

      insert_after_nav_item(
        _('Security & Compliance'),
        new_nav_item: {
          nav_item: _('Deployments'),
          nav_sub_items: [
            _('Feature Flags'),
            _('Environments'),
            _('Releases')
          ]
        }
      )

      visit project_path(project)
    end

    it_behaves_like 'verified navigation bar'
  end
end
