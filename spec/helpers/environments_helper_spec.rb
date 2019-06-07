# frozen_string_literal: true

require 'spec_helper'

describe EnvironmentsHelper do
  set(:environment) { create(:environment) }
  set(:project) { environment.project }
  set(:user) { create(:user) }

  describe '#metrics_data' do
    before do
      # This is so that this spec also passes in EE.
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).and_return(true)
    end

    let(:metrics_data) { helper.metrics_data(project, environment) }

    it 'returns data' do
      expect(metrics_data).to include(
        'settings-path' => edit_project_service_path(project, 'prometheus'),
        'clusters-path' => project_clusters_path(project),
        'current-environment-name': environment.name,
        'documentation-path' => help_page_path('administration/monitoring/prometheus/index.md'),
        'empty-getting-started-svg-path' => match_asset_path('/assets/illustrations/monitoring/getting_started.svg'),
        'empty-loading-svg-path' => match_asset_path('/assets/illustrations/monitoring/loading.svg'),
        'empty-no-data-svg-path' => match_asset_path('/assets/illustrations/monitoring/no_data.svg'),
        'empty-unable-to-connect-svg-path' => match_asset_path('/assets/illustrations/monitoring/unable_to_connect.svg'),
        'metrics-endpoint' => additional_metrics_project_environment_path(project, environment, format: :json),
        'deployment-endpoint' => project_environment_deployments_path(project, environment, format: :json),
        'environments-endpoint': project_environments_path(project, format: :json),
        'project-path' => project_path(project),
        'tags-path' => project_tags_path(project),
        'has-metrics' => "#{environment.has_metrics?}",
        'external-dashboard-url' => nil
      )
    end

    context 'with metrics_setting' do
      before do
        create(:project_metrics_setting, project: project, external_dashboard_url: 'http://gitlab.com')
      end

      it 'adds external_dashboard_url' do
        expect(metrics_data['external-dashboard-url']).to eq('http://gitlab.com')
      end
    end
  end
end
