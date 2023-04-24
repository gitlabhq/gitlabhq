# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Monitor dropdown sidebar', :aggregate_failures, feature_category: :shared do
  let_it_be_with_reload(:project) { create(:project, :internal, :repository) }
  let_it_be(:user) { create(:user) }

  let(:role) { nil }

  before do
    project.add_role(user, role) if role
    sign_in(user)
    stub_feature_flags(remove_monitor_metrics: false)
  end

  shared_examples 'shows Monitor menu based on the access level' do
    using RSpec::Parameterized::TableSyntax

    let(:enabled) { Featurable::PRIVATE }
    let(:disabled) { Featurable::DISABLED }

    where(:monitor_level, :render) do
      ref(:enabled)  | true
      ref(:disabled) | false
    end

    with_them do
      it 'renders when expected to' do
        project.project_feature.update_attribute(:monitor_access_level, monitor_level)

        visit project_issues_path(project)

        if render
          expect(page).to have_selector('a.shortcuts-monitor', text: 'Monitor')
        else
          expect(page).not_to have_selector('a.shortcuts-monitor')
        end
      end
    end
  end

  context 'when user is not a member' do
    let(:access_level) { ProjectFeature::PUBLIC }

    before do
      project.project_feature.update_attribute(:monitor_access_level, access_level)
    end

    it 'has the correct `Monitor` menu items', :aggregate_failures do
      visit project_issues_path(project)
      expect(page).to have_selector('a.shortcuts-monitor', text: 'Monitor')
      expect(page).to have_link('Incidents', href: project_incidents_path(project))
      expect(page).to have_link('Environments', href: project_environments_path(project))

      expect(page).not_to have_link('Metrics', href: project_metrics_dashboard_path(project))
      expect(page).not_to have_link('Alerts', href: project_alert_management_index_path(project))
      expect(page).not_to have_link('Error Tracking', href: project_error_tracking_index_path(project))
      expect(page).not_to have_link('Kubernetes', href: project_clusters_path(project))
    end

    context 'when monitor project feature is PRIVATE' do
      let(:access_level) { ProjectFeature::PRIVATE }

      it 'does not show the `Monitor` menu' do
        expect(page).not_to have_selector('a.shortcuts-monitor')
      end
    end

    context 'when monitor project feature is DISABLED' do
      let(:access_level) { ProjectFeature::DISABLED }

      it 'does not show the `Monitor` menu' do
        expect(page).not_to have_selector('a.shortcuts-monitor')
      end
    end
  end

  context 'when user has guest role' do
    let(:role) { :guest }

    it 'has the correct `Monitor` menu items' do
      visit project_issues_path(project)
      expect(page).to have_selector('a.shortcuts-monitor', text: 'Monitor')
      expect(page).to have_link('Incidents', href: project_incidents_path(project))
      expect(page).to have_link('Environments', href: project_environments_path(project))

      expect(page).not_to have_link('Metrics', href: project_metrics_dashboard_path(project))
      expect(page).not_to have_link('Alerts', href: project_alert_management_index_path(project))
      expect(page).not_to have_link('Error Tracking', href: project_error_tracking_index_path(project))
      expect(page).not_to have_link('Kubernetes', href: project_clusters_path(project))
    end

    it_behaves_like 'shows Monitor menu based on the access level'
  end

  context 'when user has reporter role' do
    let(:role) { :reporter }

    it 'has the correct `Monitor` menu items' do
      visit project_issues_path(project)
      expect(page).to have_link('Metrics', href: project_metrics_dashboard_path(project))
      expect(page).to have_link('Incidents', href: project_incidents_path(project))
      expect(page).to have_link('Environments', href: project_environments_path(project))
      expect(page).to have_link('Error Tracking', href: project_error_tracking_index_path(project))

      expect(page).not_to have_link('Alerts', href: project_alert_management_index_path(project))
      expect(page).not_to have_link('Kubernetes', href: project_clusters_path(project))
    end

    it_behaves_like 'shows Monitor menu based on the access level'
  end

  context 'when user has developer role' do
    let(:role) { :developer }

    it 'has the correct `Monitor` menu items' do
      visit project_issues_path(project)
      expect(page).to have_link('Metrics', href: project_metrics_dashboard_path(project))
      expect(page).to have_link('Alerts', href: project_alert_management_index_path(project))
      expect(page).to have_link('Incidents', href: project_incidents_path(project))
      expect(page).to have_link('Environments', href: project_environments_path(project))
      expect(page).to have_link('Error Tracking', href: project_error_tracking_index_path(project))
      expect(page).to have_link('Kubernetes', href: project_clusters_path(project))
    end

    it_behaves_like 'shows Monitor menu based on the access level'
  end

  context 'when user has maintainer role' do
    let(:role) { :maintainer }

    it 'has the correct `Monitor` menu items' do
      visit project_issues_path(project)
      expect(page).to have_link('Metrics', href: project_metrics_dashboard_path(project))
      expect(page).to have_link('Alerts', href: project_alert_management_index_path(project))
      expect(page).to have_link('Incidents', href: project_incidents_path(project))
      expect(page).to have_link('Environments', href: project_environments_path(project))
      expect(page).to have_link('Error Tracking', href: project_error_tracking_index_path(project))
      expect(page).to have_link('Kubernetes', href: project_clusters_path(project))
    end

    it_behaves_like 'shows Monitor menu based on the access level'
  end
end
