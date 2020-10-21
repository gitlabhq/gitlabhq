# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Operations dropdown sidebar' do
  let_it_be(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_role(user, role)
    sign_in(user)
    visit project_issues_path(project)
  end

  context 'user has guest role' do
    let(:role) { :guest }

    it 'has the correct `Operations` menu items' do
      expect(page).to have_link(title: 'Incidents', href: project_incidents_path(project))

      expect(page).not_to have_link(title: 'Metrics', href: project_metrics_dashboard_path(project))
      expect(page).not_to have_link(title: 'Alerts', href: project_alert_management_index_path(project))
      expect(page).not_to have_link(title: 'Environments', href: project_environments_path(project))
      expect(page).not_to have_link(title: 'Error Tracking', href: project_error_tracking_index_path(project))
      expect(page).not_to have_link(title: 'Product Analytics', href: project_product_analytics_path(project))
      expect(page).not_to have_link(title: 'Serverless', href: project_serverless_functions_path(project))
      expect(page).not_to have_link(title: 'Logs', href: project_logs_path(project))
      expect(page).not_to have_link(title: 'Kubernetes', href: project_clusters_path(project))
    end
  end

  context 'user has reporter role' do
    let(:role) { :reporter }

    it 'has the correct `Operations` menu items' do
      expect(page).to have_link(title: 'Metrics', href: project_metrics_dashboard_path(project))
      expect(page).to have_link(title: 'Incidents', href: project_incidents_path(project))
      expect(page).to have_link(title: 'Environments', href: project_environments_path(project))
      expect(page).to have_link(title: 'Error Tracking', href: project_error_tracking_index_path(project))
      expect(page).to have_link(title: 'Product Analytics', href: project_product_analytics_path(project))

      expect(page).not_to have_link(title: 'Alerts', href: project_alert_management_index_path(project))
      expect(page).not_to have_link(title: 'Serverless', href: project_serverless_functions_path(project))
      expect(page).not_to have_link(title: 'Logs', href: project_logs_path(project))
      expect(page).not_to have_link(title: 'Kubernetes', href: project_clusters_path(project))
    end
  end

  context 'user has developer role' do
    let(:role) { :developer }

    it 'has the correct `Operations` menu items' do
      expect(page).to have_link(title: 'Metrics', href: project_metrics_dashboard_path(project))
      expect(page).to have_link(title: 'Alerts', href: project_alert_management_index_path(project))
      expect(page).to have_link(title: 'Incidents', href: project_incidents_path(project))
      expect(page).to have_link(title: 'Environments', href: project_environments_path(project))
      expect(page).to have_link(title: 'Error Tracking', href: project_error_tracking_index_path(project))
      expect(page).to have_link(title: 'Product Analytics', href: project_product_analytics_path(project))
      expect(page).to have_link(title: 'Logs', href: project_logs_path(project))

      expect(page).not_to have_link(title: 'Serverless', href: project_serverless_functions_path(project))
      expect(page).not_to have_link(title: 'Kubernetes', href: project_clusters_path(project))
    end
  end

  context 'user has maintainer role' do
    let(:role) { :maintainer }

    it 'has the correct `Operations` menu items' do
      expect(page).to have_link(title: 'Metrics', href: project_metrics_dashboard_path(project))
      expect(page).to have_link(title: 'Alerts', href: project_alert_management_index_path(project))
      expect(page).to have_link(title: 'Incidents', href: project_incidents_path(project))
      expect(page).to have_link(title: 'Environments', href: project_environments_path(project))
      expect(page).to have_link(title: 'Error Tracking', href: project_error_tracking_index_path(project))
      expect(page).to have_link(title: 'Product Analytics', href: project_product_analytics_path(project))
      expect(page).to have_link(title: 'Serverless', href: project_serverless_functions_path(project))
      expect(page).to have_link(title: 'Logs', href: project_logs_path(project))
      expect(page).to have_link(title: 'Kubernetes', href: project_clusters_path(project))
    end
  end
end
