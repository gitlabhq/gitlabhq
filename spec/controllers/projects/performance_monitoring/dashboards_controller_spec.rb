# frozen_string_literal: true

require 'spec_helper'

describe Projects::PerformanceMonitoring::DashboardsController do
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
            it 'delegates commit creation to service' do
              allow(controller).to receive(:repository).and_return(repository)
              allow(repository).to receive(:find_branch).and_return(branch)
              dashboard_attrs = {
                commit_message: commit_message,
                branch_name: branch_name,
                start_branch: 'master',
                encoding: 'text',
                file_path: '.gitlab/dashboards/custom_dashboard.yml',
                file_content: File.read('config/prometheus/common_metrics.yml')
              }

              service_instance = instance_double(::Files::CreateService)
              expect(::Files::CreateService).to receive(:new).with(project, user, dashboard_attrs).and_return(service_instance)
              expect(service_instance).to receive(:execute).and_return(status: :success)

              post :create, params: params
            end

            it 'extends dashboard template path to absolute url' do
              allow(::Files::CreateService).to receive(:new).and_return(double(execute: { status: :success }))
              allow(controller).to receive(:repository).and_return(repository)
              allow(repository).to receive(:find_branch).and_return(branch)

              expect(File).to receive(:read).with(Rails.root.join('config/prometheus/common_metrics.yml')).and_return('')

              post :create, params: params
            end

            context 'selected branch already exists' do
              it 'responds with :created status code', :aggregate_failures do
                repository.add_branch(user, branch_name, 'master')

                post :create, params: params

                expect(response).to have_gitlab_http_status :created
              end
            end

            context 'request format json' do
              it 'returns path to new file' do
                allow(::Files::CreateService).to receive(:new).and_return(double(execute: { status: :success }))
                allow(controller).to receive(:repository).and_return(repository)

                expect(repository).to receive(:find_branch).with(branch_name).and_return(branch)

                post :create, params: params

                expect(response).to have_gitlab_http_status :created
                expect(json_response).to eq('redirect_to' => "/-/ide/project/#{namespace.path}/#{project.name}/edit/#{branch_name}/-/.gitlab/dashboards/#{file_name}")
              end

              context 'files create service failure' do
                it 'returns json with failure message' do
                  allow(::Files::CreateService).to receive(:new).and_return(double(execute: { status: false, message: 'something went wrong' }))

                  post :create, params: params

                  expect(response).to have_gitlab_http_status :bad_request
                  expect(response).to set_flash[:alert].to eq('something went wrong')
                  expect(json_response).to eq('error' => 'something went wrong')
                end
              end
            end

            context 'request format html' do
              before do
                params.delete(:format)
              end

              it 'redirects to ide with new file' do
                allow(::Files::CreateService).to receive(:new).and_return(double(execute: { status: :success }))
                allow(controller).to receive(:repository).and_return(repository)

                expect(repository).to receive(:find_branch).with(branch_name).and_return(branch)

                post :create, params: params

                expect(response).to redirect_to "/-/ide/project/#{namespace.path}/#{project.name}/edit/#{branch_name}/-/.gitlab/dashboards/#{file_name}"
              end

              context 'files create service failure' do
                it 'redirects back and sets alert' do
                  allow(::Files::CreateService).to receive(:new).and_return(double(execute: { status: false, message: 'something went wrong' }))
                  allow(controller).to receive(:repository).and_return(repository)
                  allow(repository).to receive(:find_branch).and_return(branch)

                  post :create, params: params

                  expect(response).to set_flash[:alert].to eq('something went wrong')
                  expect(response).to redirect_to namespace_project_environments_path
                end
              end
            end
          end

          context 'invalid dashboard template' do
            let(:dashboard) { 'config/database.yml' }

            it 'responds 404 not found' do
              post :create, params: params

              expect(response).to have_gitlab_http_status :not_found
            end
          end

          context 'missing commit message' do
            before do
              params.delete(:commit_message)
            end

            it 'use default commit message' do
              allow(controller).to receive(:repository).and_return(repository)
              allow(repository).to receive(:find_branch).and_return(branch)
              dashboard_attrs = {
                commit_message: 'Create custom dashboard custom_dashboard.yml',
                branch_name: branch_name,
                start_branch: 'master',
                encoding: 'text',
                file_path: ".gitlab/dashboards/custom_dashboard.yml",
                file_content: File.read('config/prometheus/common_metrics.yml')
              }

              service_instance = instance_double(::Files::CreateService)
              expect(::Files::CreateService).to receive(:new).with(project, user, dashboard_attrs).and_return(service_instance)
              expect(service_instance).to receive(:execute).and_return(status: :success)

              post :create, params: params
            end
          end

          context 'missing branch' do
            let(:branch_name) { nil }

            it 'raises ActionController::ParameterMissing' do
              expect { post :create, params: params }.to raise_error ActionController::ParameterMissing
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
end
