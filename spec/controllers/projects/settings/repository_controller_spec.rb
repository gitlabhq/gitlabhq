# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::RepositoryController, feature_category: :source_code_management do
  let(:project) { create(:project_empty_repo, :public) }
  let(:user) { create(:user) }
  let(:base_params) { { namespace_id: project.namespace, project_id: project } }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET show' do
    it 'renders show with 200 status code' do
      get :show, params: base_params

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:show)
    end
  end

  describe 'PUT cleanup' do
    let(:object_map) { fixture_file_upload('spec/fixtures/bfg_object_map.txt') }

    it 'enqueues a project cleanup' do
      expect(Projects::CleanupService)
        .to receive(:enqueue)
        .with(project, user, anything)
        .and_return(status: :success)

      put :cleanup, params: base_params.merge({ project: { bfg_object_map: object_map } })

      expect(response).to redirect_to project_settings_repository_path(project)
    end

    context 'when project cleanup returns an error', :aggregate_failures do
      it 'shows an error' do
        expect(Projects::CleanupService)
          .to receive(:enqueue)
          .with(project, user, anything)
          .and_return(status: :error, message: 'error message')

        put :cleanup, params: base_params.merge({ project: { bfg_object_map: object_map } })

        expect(controller).to set_flash[:alert].to('error message')
        expect(response).to redirect_to project_settings_repository_path(project)
      end
    end
  end

  describe 'POST create_deploy_token' do
    let(:good_deploy_token_params) do
      {
        name: 'name',
        expires_at: 1.day.from_now.to_datetime.to_s,
        username: 'deployer',
        read_repository: '1',
        deploy_token_type: DeployToken.deploy_token_types[:project_type]
      }
    end

    let(:request_params) { base_params.merge({ deploy_token: deploy_token_params }) }

    subject { post :create_deploy_token, params: request_params, format: :json }

    context('a good request') do
      let(:deploy_token_params) { good_deploy_token_params }
      let(:expected_response) do
        {
          'id' => be_a(Integer),
          'name' => deploy_token_params[:name],
          'username' => deploy_token_params[:username],
          'expires_at' => Time.zone.parse(deploy_token_params[:expires_at]),
          'token' => be_a(String),
          'expired' => false,
          'revoked' => false,
          'scopes' => deploy_token_params.inject([]) do |scopes, kv|
            key, value = kv
            key.to_s.start_with?('read_') && value.to_i != 0 ? scopes << key.to_s : scopes
          end
        }
      end

      it 'creates the deploy token' do
        subject

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/deploy_token')
        expect(json_response).to match(expected_response)
      end
    end

    context('a bad request') do
      let(:deploy_token_params) { good_deploy_token_params.except(:read_repository) }
      let(:expected_response) { { 'message' => "Scopes can't be blank" } }

      it 'does not create the deploy token' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to match(expected_response)
      end
    end

    context('an invalid request') do
      let(:deploy_token_params) { good_deploy_token_params.except(:name) }

      it 'raises a validation error' do
        expect { subject }.to raise_error(ActiveRecord::StatementInvalid)
      end
    end
  end

  describe 'PUT update' do
    let(:project) { create(:project, :repository) }

    context 'when updating default branch' do
      let!(:previous_default_branch) { project.default_branch }

      let(:new_default_branch) { 'feature' }
      let(:request_params) { base_params.merge({ project: project_params_attributes }) }

      subject { put :update, params: request_params }

      context('with a good request') do
        let(:project_params_attributes) { { default_branch: new_default_branch } }

        it "updates default branch and redirect to project_settings_repository_path" do
          expect do
            subject
          end.to change {
            Project.find(project.id).default_branch # refind to reset the default branch cache
          }.from(previous_default_branch).to(new_default_branch)

          expect(response).to redirect_to project_settings_repository_path(project)
          expect(controller).to set_flash[:notice].to("Project settings were successfully updated.")
        end
      end

      context('with a bad input') do
        let(:project_params_attributes) { { default_branch: 'non_existent_branch' } }

        it "does not update default branch and shows an alert" do
          expect do
            subject
          end.not_to change {
            Project.find(project.id).default_branch # refind to reset the default branch cache
          }

          expect(response).to redirect_to project_settings_repository_path(project)
          expect(controller).to set_flash[:alert].to("Could not set the default branch")
        end
      end
    end

    context 'when updating branch names template from issues' do
      let(:branch_name_template) { 'feat/GL-%{id}-%{title}' }

      let(:request_params) { base_params.merge({ project: project_params_attributes }) }

      subject { put :update, params: request_params }

      context('with a good request') do
        let(:project_params_attributes) { { issue_branch_template: branch_name_template } }

        it "updates issue_branch_template and redirect to project_settings_repository_path" do
          subject

          expect(response).to redirect_to project_settings_repository_path(project)
          expect(controller).to set_flash[:notice].to("Project settings were successfully updated.")
          expect(project.reload.issue_branch_template).to eq(branch_name_template)
        end
      end

      context('with a bad input') do
        let(:project_params_attributes) { { issue_branch_template: 'a' * 260 } }

        it "updates issue_branch_template and redirect to project_settings_repository_path" do
          subject

          expect(response).to redirect_to project_settings_repository_path(project)
          expect(controller).to set_flash[:alert].to("Project setting issue branch template is too long (maximum is 255 characters)")
          expect(project.reload.issue_branch_template).to eq(nil)
        end
      end
    end
  end
end
