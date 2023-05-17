# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MetricsDashboard do
  include MetricsDashboardHelpers

  describe 'GET #metrics_dashboard' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { project_with_dashboard('.gitlab/dashboards/test.yml') }
    let_it_be(:environment) { create(:environment, project: project) }

    before do
      sign_in(user)
      project.add_maintainer(user)
    end

    controller(::ApplicationController) do
      include MetricsDashboard
    end

    let(:json_response) do
      routes.draw { get "metrics_dashboard" => "anonymous#metrics_dashboard" }
      response = get :metrics_dashboard, format: :json

      response.parsed_body
    end

    context 'when no parameters are provided' do
      it 'returns an error json_response' do
        expect(json_response['status']).to eq('error')
      end
    end

    context 'when params are provided' do
      let(:params) { { environment: environment } }

      before do
        allow(controller).to receive(:project).and_return(project)
        allow(controller)
          .to receive(:metrics_dashboard_params)
          .and_return(params)
      end

      it 'returns the specified dashboard' do
        expect(json_response['dashboard']['dashboard']).to eq('Environment metrics')
        expect(json_response).not_to have_key('all_dashboards')
        expect(json_response).to have_key('metrics_data')
      end

      context 'when the params are in an alternate format' do
        let(:params) { ActionController::Parameters.new({ environment: environment }).permit! }

        it 'returns the specified dashboard' do
          expect(json_response['dashboard']['dashboard']).to eq('Environment metrics')
          expect(json_response).not_to have_key('all_dashboards')
          expect(json_response).to have_key('metrics_data')
        end
      end

      context 'when environment for dashboard is available' do
        let(:params) { { environment: environment } }

        before do
          allow(controller).to receive(:project).and_return(project)
          allow(controller).to receive(:environment).and_return(environment)
          allow(controller)
            .to receive(:metrics_dashboard_params)
                  .and_return(params)
        end

        it 'returns the specified dashboard' do
          expect(json_response['dashboard']['dashboard']).to eq('Environment metrics')
          expect(json_response).not_to have_key('all_dashboards')
          expect(json_response).to have_key('metrics_data')
        end
      end

      context 'when dashboard path includes encoded characters' do
        let(:params) { { dashboard_path: 'dashboard%26copy.yml' } }

        before do
          allow(controller)
            .to receive(:metrics_dashboard_params)
                  .and_return(params)
        end

        it 'decodes dashboard path' do
          expect(::Gitlab::Metrics::Dashboard::Finder).to receive(:find).with(anything, anything, hash_including(dashboard_path: 'dashboard&copy.yml'))

          json_response
        end
      end

      context 'when parameters are provided and the list of all dashboards is required' do
        before do
          allow(controller).to receive(:include_all_dashboards?).and_return(true)
        end

        it 'returns a dashboard in addition to the list of dashboards' do
          expect(json_response['dashboard']['dashboard']).to eq('Environment metrics')
          expect(json_response).to have_key('all_dashboards')
        end

        context 'in all_dashboard list' do
          let(:system_dashboard) { json_response['all_dashboards'].find { |dashboard| dashboard["system_dashboard"] == true } }

          let(:project_dashboard) do
            json_response['all_dashboards'].find do |dashboard|
              dashboard['path'] == '.gitlab/dashboards/test.yml'
            end
          end

          it 'includes project_blob_path only for project dashboards' do
            expect(system_dashboard['project_blob_path']).to be_nil
            expect(project_dashboard['project_blob_path']).to eq("/#{project.namespace.path}/#{project.path}/-/blob/master/.gitlab/dashboards/test.yml")
          end

          it 'allows editing only for project dashboards' do
            expect(system_dashboard['can_edit']).to be(false)
            expect(project_dashboard['can_edit']).to be(true)
          end

          it 'includes out_of_the_box_dashboard key' do
            expect(system_dashboard['out_of_the_box_dashboard']).to be(true)
            expect(project_dashboard['out_of_the_box_dashboard']).to be(false)
          end

          describe 'project permissions' do
            using RSpec::Parameterized::TableSyntax

            where(:can_collaborate, :system_can_edit, :project_can_edit) do
              false | false | false
              true  | false | true
            end

            with_them do
              before do
                allow(controller).to receive(:can_collaborate_with_project?).and_return(can_collaborate)
              end

              it "sets can_edit appropriately" do
                expect(system_dashboard["can_edit"]).to eq(system_can_edit)
                expect(project_dashboard["can_edit"]).to eq(project_can_edit)
              end
            end
          end

          context 'starred dashboards' do
            let_it_be(:dashboard_yml) { fixture_file('lib/gitlab/metrics/dashboard/sample_dashboard.yml') }
            let_it_be(:dashboards) do
              {
                '.gitlab/dashboards/test.yml' => dashboard_yml,
                '.gitlab/dashboards/anomaly.yml' => dashboard_yml,
                '.gitlab/dashboards/errors.yml' => dashboard_yml
              }
            end

            let_it_be(:project) { create(:project, :custom_repo, files: dashboards) }

            before do
              create(:metrics_users_starred_dashboard, user: user, project: project, dashboard_path: '.gitlab/dashboards/errors.yml')
              create(:metrics_users_starred_dashboard, user: user, project: project, dashboard_path: '.gitlab/dashboards/test.yml')
            end

            it 'adds starred dashboard information and sorts the list' do
              all_dashboards = json_response['all_dashboards'].map { |dashboard| dashboard.slice('display_name', 'starred', 'user_starred_path') }
              expected_response = [
                { "display_name" => "anomaly.yml", "starred" => false, 'user_starred_path' => api_v4_projects_metrics_user_starred_dashboards_path(id: project.id, params: { dashboard_path: '.gitlab/dashboards/anomaly.yml' }) },
                { "display_name" => "errors.yml", "starred" => true, 'user_starred_path' => api_v4_projects_metrics_user_starred_dashboards_path(id: project.id, params: { dashboard_path: '.gitlab/dashboards/errors.yml' }) },
                { "display_name" => "K8s pod health", "starred" => false, 'user_starred_path' => api_v4_projects_metrics_user_starred_dashboards_path(id: project.id, params: { dashboard_path: 'config/prometheus/pod_metrics.yml' }) },
                { "display_name" => "Overview", "starred" => false, 'user_starred_path' => api_v4_projects_metrics_user_starred_dashboards_path(id: project.id, params: { dashboard_path: 'config/prometheus/common_metrics.yml' }) },
                { "display_name" => "test.yml", "starred" => true, 'user_starred_path' => api_v4_projects_metrics_user_starred_dashboards_path(id: project.id, params: { dashboard_path: '.gitlab/dashboards/test.yml' }) }
              ]

              expect(all_dashboards).to eq(expected_response)
            end
          end
        end
      end
    end
  end
end
