# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::PerformanceMonitoring::DashboardsController do
  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:namespace) }

  let!(:project) { create(:project, :repository, name: 'dashboard-project', namespace: namespace) }
  let(:repository) { project.repository }
  let(:branch) { double(name: branch_name) }
  let(:commit_message) { 'test' }
  let(:branch_name) { "#{Time.current.to_i}_dashboard_new_branch" }
  let(:dashboard) { 'config/prometheus/common_metrics.yml' }
  let(:file_name) { 'custom_dashboard.yml' }
  let(:params) do
    {
      namespace_id: namespace,
      project_id: project,
      dashboard: dashboard,
      file_name: file_name,
      commit_message: commit_message,
      branch: branch_name,
      format: :json
    }
  end

  describe 'POST #create' do
    context 'authenticated user' do
      before do
        sign_in(user)
      end

      context 'project with repository feature' do
        context 'with rights to push to the repository' do
          before do
            project.add_maintainer(user)
          end

          context 'valid parameters' do
            it 'delegates cloning to ::Metrics::Dashboard::CloneDashboardService' do
              allow(controller).to receive(:repository).and_return(repository)
              allow(repository).to receive(:find_branch).and_return(branch)
              dashboard_attrs = {
                dashboard: dashboard,
                file_name: file_name,
                commit_message: commit_message,
                branch: branch_name
              }

              service_instance = instance_double(::Metrics::Dashboard::CloneDashboardService)
              expect(::Metrics::Dashboard::CloneDashboardService).to receive(:new).with(project, user, dashboard_attrs).and_return(service_instance)
              expect(service_instance).to receive(:execute).and_return(status: :success, http_status: :created, dashboard: { path: 'dashboard/path' })

              post :create, params: params
            end

            context 'request format json' do
              it 'returns services response' do
                allow(::Metrics::Dashboard::CloneDashboardService).to receive(:new).and_return(double(execute: { status: :success, dashboard: { path: ".gitlab/dashboards/#{file_name}" }, http_status: :created }))
                allow(controller).to receive(:repository).and_return(repository)
                allow(repository).to receive(:find_branch).and_return(branch)

                post :create, params: params

                expect(response).to have_gitlab_http_status :created
                expect(controller).to set_flash[:notice].to eq("Your dashboard has been copied. You can <a href=\"/-/ide/project/#{namespace.path}/#{project.name}/edit/#{branch_name}/-/.gitlab/dashboards/#{file_name}\">edit it here</a>.")
                expect(json_response).to eq('status' => 'success', 'dashboard' => { 'path' => ".gitlab/dashboards/#{file_name}" })
              end

              context 'Metrics::Dashboard::CloneDashboardService failure' do
                it 'returns json with failure message', :aggregate_failures do
                  allow(::Metrics::Dashboard::CloneDashboardService).to receive(:new).and_return(double(execute: { status: :error, message: 'something went wrong', http_status: :bad_request }))

                  post :create, params: params

                  expect(response).to have_gitlab_http_status :bad_request
                  expect(json_response).to eq('error' => 'something went wrong')
                end
              end

              %w(commit_message file_name dashboard).each do |param|
                context "param #{param} is missing" do
                  let(param.to_s) { nil }

                  it 'responds with bad request status and error message', :aggregate_failures do
                    post :create, params: params

                    expect(response).to have_gitlab_http_status :bad_request
                    expect(json_response).to eq('error' => "Request parameter #{param} is missing.")
                  end
                end
              end

              context "param branch_name is missing" do
                let(:branch_name) { nil }

                it 'responds with bad request status and error message', :aggregate_failures do
                  post :create, params: params

                  expect(response).to have_gitlab_http_status :bad_request
                  expect(json_response).to eq('error' => "Request parameter branch is missing.")
                end
              end
            end
          end
        end

        context 'without rights to push to repository' do
          before do
            project.add_guest(user)
          end

          it 'responds with :forbidden status code' do
            post :create, params: params

            expect(response).to have_gitlab_http_status :forbidden
          end
        end
      end

      context 'project without repository feature' do
        let!(:project) { create(:project, name: 'dashboard-project', namespace: namespace) }

        it 'responds with :not_found status code' do
          post :create, params: params

          expect(response).to have_gitlab_http_status :not_found
        end
      end
    end
  end

  describe 'PUT #update' do
    context 'authenticated user' do
      before do
        sign_in(user)
      end

      let(:file_content) do
        {
          "dashboard" => "Dashboard Title",
          "panel_groups" => [{
            "group" => "Group Title",
            "panels" => [{
              "type" => "area-chart",
              "title" => "Chart Title",
              "y_label" => "Y-Axis",
              "metrics" => [{
                "id" => "metric_of_ages",
                "unit" => "count",
                "label" => "Metric of Ages",
                "query_range" => "http_requests_total"
              }]
            }]
          }]
        }
      end

      let(:params) do
        {
          namespace_id: namespace,
          project_id: project,
          dashboard: dashboard,
          file_name: file_name,
          file_content: file_content,
          commit_message: commit_message,
          branch: branch_name,
          format: :json
        }
      end

      context 'project with repository feature' do
        context 'with rights to push to the repository' do
          before do
            project.add_maintainer(user)
          end

          context 'valid parameters' do
            context 'request format json' do
              let(:update_dashboard_service_params) { params.except(:namespace_id, :project_id, :format) }

              let(:update_dashboard_service_results) do
                {
                  status: :success,
                  http_status: :created,
                  dashboard: {
                    path: ".gitlab/dashboards/custom_dashboard.yml",
                    display_name: "custom_dashboard.yml",
                    default: false,
                    system_dashboard: false
                  }
                }
              end

              let(:update_dashboard_service) { instance_double(::Metrics::Dashboard::UpdateDashboardService, execute: update_dashboard_service_results) }

              it 'returns path to new file' do
                allow(controller).to receive(:repository).and_return(repository)
                allow(repository).to receive(:find_branch).and_return(branch)
                allow(::Metrics::Dashboard::UpdateDashboardService).to receive(:new).with(project, user, update_dashboard_service_params).and_return(update_dashboard_service)

                put :update, params: params

                expect(response).to have_gitlab_http_status :created
                expect(controller).to set_flash[:notice].to eq("Your dashboard has been updated. You can <a href=\"/-/ide/project/#{namespace.path}/#{project.name}/edit/#{branch_name}/-/.gitlab/dashboards/#{file_name}\">edit it here</a>.")
                expect(json_response).to eq('status' => 'success', 'dashboard' => { 'default' => false, 'display_name' => "custom_dashboard.yml", 'path' => ".gitlab/dashboards/#{file_name}", 'system_dashboard' => false })
              end

              context 'UpdateDashboardService failure' do
                it 'returns json with failure message' do
                  allow(::Metrics::Dashboard::UpdateDashboardService).to receive(:new).and_return(double(execute: { status: :error, message: 'something went wrong', http_status: :bad_request }))

                  put :update, params: params

                  expect(response).to have_gitlab_http_status :bad_request
                  expect(json_response).to eq('error' => 'something went wrong')
                end
              end
            end
          end

          context 'missing branch' do
            let(:branch_name) { nil }

            it 'raises responds with :bad_request status code and error message' do
              put :update, params: params

              expect(response).to have_gitlab_http_status :bad_request
              expect(json_response).to eq('error' => "Request parameter branch is missing.")
            end
          end
        end

        context 'without rights to push to repository' do
          before do
            project.add_guest(user)
          end

          it 'responds with :forbidden status code' do
            put :update, params: params

            expect(response).to have_gitlab_http_status :forbidden
          end
        end
      end

      context 'project without repository feature' do
        let!(:project) { create(:project, name: 'dashboard-project', namespace: namespace) }

        it 'responds with :not_found status code' do
          put :update, params: params

          expect(response).to have_gitlab_http_status :not_found
        end
      end
    end
  end
end
