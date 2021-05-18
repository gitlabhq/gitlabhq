# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Monitor dropdown sidebar', :aggregate_failures do
  let_it_be_with_reload(:project) { create(:project, :internal, :repository) }

  let(:user) { create(:user) }
  let(:access_level) { ProjectFeature::PUBLIC }
  let(:role) { nil }

  before do
    project.add_role(user, role) if role
    project.project_feature.update_attribute(:operations_access_level, access_level)

    sign_in(user)
    visit project_issues_path(project)
  end

  shared_examples 'shows Monitor menu based on the access level' do
    context 'when operations project feature is PRIVATE' do
      let(:access_level) { ProjectFeature::PRIVATE }

      it 'shows the `Monitor` menu' do
        expect(page).to have_selector('a.shortcuts-monitor', text: 'Monitor')
      end
    end

    context 'when operations project feature is DISABLED' do
      let(:access_level) { ProjectFeature::DISABLED }

      it 'does not show the `Monitor` menu' do
        expect(page).not_to have_selector('a.shortcuts-monitor')
      end
    end
  end

  context 'user is not a member' do
    it 'has the correct `Monitor` menu items', :aggregate_failures do
      expect(page).to have_selector('a.shortcuts-monitor', text: 'Monitor')
      expect(page).to have_link('Incidents', href: project_incidents_path(project))
      expect(page).to have_link('Environments', href: project_environments_path(project))

      expect(page).not_to have_link('Metrics', href: project_metrics_dashboard_path(project))
      expect(page).not_to have_link('Alerts', href: project_alert_management_index_path(project))
      expect(page).not_to have_link('Error Tracking', href: project_error_tracking_index_path(project))
      expect(page).not_to have_link('Product Analytics', href: project_product_analytics_path(project))
      expect(page).not_to have_link('Serverless', href: project_serverless_functions_path(project))
      expect(page).not_to have_link('Logs', href: project_logs_path(project))
      expect(page).not_to have_link('Kubernetes', href: project_clusters_path(project))
    end

    context 'when operations project feature is PRIVATE' do
      let(:access_level) { ProjectFeature::PRIVATE }

      it 'does not show the `Monitor` menu' do
        expect(page).not_to have_selector('a.shortcuts-monitor')
      end
    end

    context 'when operations project feature is DISABLED' do
      let(:access_level) { ProjectFeature::DISABLED }

      it 'does not show the `Operations` menu' do
        expect(page).not_to have_selector('a.shortcuts-monitor')
      end
    end
  end

  context 'user has guest role' do
    let(:role) { :guest }

    it 'has the correct `Monitor` menu items' do
      expect(page).to have_selector('a.shortcuts-monitor', text: 'Monitor')
      expect(page).to have_link('Incidents', href: project_incidents_path(project))
      expect(page).to have_link('Environments', href: project_environments_path(project))

      expect(page).not_to have_link('Metrics', href: project_metrics_dashboard_path(project))
      expect(page).not_to have_link('Alerts', href: project_alert_management_index_path(project))
      expect(page).not_to have_link('Error Tracking', href: project_error_tracking_index_path(project))
      expect(page).not_to have_link('Product Analytics', href: project_product_analytics_path(project))
      expect(page).not_to have_link('Serverless', href: project_serverless_functions_path(project))
      expect(page).not_to have_link('Logs', href: project_logs_path(project))
      expect(page).not_to have_link('Kubernetes', href: project_clusters_path(project))
    end

    it_behaves_like 'shows Monitor menu based on the access level'
  end

  context 'user has reporter role' do
    let(:role) { :reporter }

    it 'has the correct `Monitor` menu items' do
      expect(page).to have_link('Metrics', href: project_metrics_dashboard_path(project))
      expect(page).to have_link('Incidents', href: project_incidents_path(project))
      expect(page).to have_link('Environments', href: project_environments_path(project))
      expect(page).to have_link('Error Tracking', href: project_error_tracking_index_path(project))
      expect(page).to have_link('Product Analytics', href: project_product_analytics_path(project))

      expect(page).not_to have_link('Alerts', href: project_alert_management_index_path(project))
      expect(page).not_to have_link('Serverless', href: project_serverless_functions_path(project))
      expect(page).not_to have_link('Logs', href: project_logs_path(project))
      expect(page).not_to have_link('Kubernetes', href: project_clusters_path(project))
    end

    it_behaves_like 'shows Monitor menu based on the access level'
  end

  context 'user has developer role' do
    let(:role) { :developer }

    it 'has the correct `Monitor` menu items' do
      expect(page).to have_link('Metrics', href: project_metrics_dashboard_path(project))
      expect(page).to have_link('Alerts', href: project_alert_management_index_path(project))
      expect(page).to have_link('Incidents', href: project_incidents_path(project))
      expect(page).to have_link('Environments', href: project_environments_path(project))
      expect(page).to have_link('Error Tracking', href: project_error_tracking_index_path(project))
      expect(page).to have_link('Product Analytics', href: project_product_analytics_path(project))
      expect(page).to have_link('Logs', href: project_logs_path(project))

      expect(page).not_to have_link('Serverless', href: project_serverless_functions_path(project))
      expect(page).not_to have_link('Kubernetes', href: project_clusters_path(project))
    end

    it_behaves_like 'shows Monitor menu based on the access level'
  end

  context 'user has maintainer role' do
    let(:role) { :maintainer }

    it 'has the correct `Monitor` menu items' do
      expect(page).to have_link('Metrics', href: project_metrics_dashboard_path(project))
      expect(page).to have_link('Alerts', href: project_alert_management_index_path(project))
      expect(page).to have_link('Incidents', href: project_incidents_path(project))
      expect(page).to have_link('Environments', href: project_environments_path(project))
      expect(page).to have_link('Error Tracking', href: project_error_tracking_index_path(project))
      expect(page).to have_link('Product Analytics', href: project_product_analytics_path(project))
      expect(page).to have_link('Serverless', href: project_serverless_functions_path(project))
      expect(page).to have_link('Logs', href: project_logs_path(project))
      expect(page).to have_link('Kubernetes', href: project_clusters_path(project))
    end

    it_behaves_like 'shows Monitor menu based on the access level'
  end
end
