# frozen_string_literal: true
require_relative 'cluster_with_prometheus'

module QA
  RSpec.describe 'Monitor', :orchestrated, :kubernetes, :requires_admin, quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/241448', type: :investigating } do
    include_context "cluster with Prometheus installed"

    before do
      Flow::Login.sign_in_unless_signed_in
      @project.visit!
    end

    it 'configures custom metrics', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/872' do
      verify_add_custom_metric
      verify_edit_custom_metric
      verify_delete_custom_metric
    end

    it 'duplicates to create dashboard to custom', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/871' do
      Page::Project::Menu.perform(&:go_to_monitor_metrics)

      Page::Project::Monitor::Metrics::Show.perform do |on_dashboard|
        on_dashboard.duplicate_dashboard

        expect(on_dashboard).to have_metrics
        expect(on_dashboard).to have_edit_dashboard_enabled
      end
    end

    it 'verifies data on filtered deployed environment', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/874' do
      Page::Project::Menu.perform(&:go_to_monitor_metrics)

      Page::Project::Monitor::Metrics::Show.perform do |on_dashboard|
        on_dashboard.filter_environment

        expect(on_dashboard).to have_metrics
      end
    end

    it 'filters using the quick range', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/873' do
      Page::Project::Menu.perform(&:go_to_monitor_metrics)

      Page::Project::Monitor::Metrics::Show.perform do |on_dashboard|
        on_dashboard.show_last('30 minutes')
        expect(on_dashboard).to have_metrics

        on_dashboard.show_last('3 hours')
        expect(on_dashboard).to have_metrics

        on_dashboard.show_last('1 day')
        expect(on_dashboard).to have_metrics
      end
    end

    it 'observes cluster health graph', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/920' do
      Page::Project::Menu.perform(&:go_to_infrastructure_kubernetes)

      Page::Project::Infrastructure::Kubernetes::Index.perform do |cluster_list|
        cluster_list.click_on_cluster(@cluster)
      end

      Page::Project::Infrastructure::Kubernetes::Show.perform do |cluster_panel|
        cluster_panel.open_health
        cluster_panel.wait_for_cluster_health
      end
    end

    it 'uses templating variables for metrics dashboards' do
      templating_dashboard_yml = Pathname
                                     .new(__dir__)
                                     .join('../../../../fixtures/metrics_dashboards/templating.yml')

      Resource::Repository::ProjectPush.fabricate! do |push|
        push.project = @project
        push.file_name = '.gitlab/dashboards/templating.yml'
        push.file_content = File.read(templating_dashboard_yml)
        push.commit_message = 'Add templating in dashboard file'
        push.new_branch = false
      end

      Page::Project::Menu.perform(&:go_to_monitor_metrics)

      Page::Project::Monitor::Metrics::Show.perform do |dashboard|
        dashboard.select_dashboard('templating.yml')

        expect(dashboard).to have_template_metric('CPU usage GitLab Runner')
        expect(dashboard).to have_template_metric('Memory usage Postgresql')
        expect(dashboard).to have_templating_variable('GitLab Runner')
        expect(dashboard).to have_templating_variable('Postgresql')
      end
    end

    private

    def verify_add_custom_metric
      Page::Project::Menu.perform(&:go_to_integrations_settings)
      Page::Project::Settings::Integrations.perform(&:click_on_prometheus_integration)

      Page::Project::Settings::Services::Prometheus.perform do |metrics_panel|
        metrics_panel.click_on_new_metric
        metrics_panel.add_custom_metric
      end

      Page::Project::Menu.perform(&:go_to_monitor_metrics)

      Page::Project::Monitor::Metrics::Show.perform do |on_dashboard|
        expect(on_dashboard).to have_custom_metric('HTTP Requests Total')
      end
    end

    def verify_edit_custom_metric
      Page::Project::Menu.perform(&:go_to_integrations_settings)
      Page::Project::Settings::Integrations.perform(&:click_on_prometheus_integration)
      Page::Project::Settings::Services::Prometheus.perform do |metrics_panel|
        metrics_panel.click_on_custom_metric('Business / HTTP Requests Total (req/sec)')
        metrics_panel.edit_custom_metric
      end

      Page::Project::Menu.perform(&:go_to_monitor_metrics)

      Page::Project::Monitor::Metrics::Show.perform do |on_dashboard|
        expect(on_dashboard).to have_custom_metric('Throughput')
      end
    end

    def verify_delete_custom_metric
      Page::Project::Menu.perform(&:go_to_integrations_settings)
      Page::Project::Settings::Integrations.perform(&:click_on_prometheus_integration)

      Page::Project::Settings::Services::Prometheus.perform do |metrics_panel|
        metrics_panel.click_on_custom_metric('Business / Throughput (req/sec)')
        metrics_panel.delete_custom_metric
      end

      Page::Project::Menu.perform(&:go_to_monitor_metrics)

      Page::Project::Monitor::Metrics::Show.perform do |on_dashboard|
        expect(on_dashboard).not_to have_custom_metric('Throughput')
      end
    end
  end
end
