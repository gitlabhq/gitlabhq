# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DeploymentsController, feature_category: :deployment_management do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:environment) { create(:environment, name: 'production', project: project) }

  before do
    project.add_maintainer(user)

    sign_in(user)
  end

  describe 'GET #index' do
    it 'returns list of deployments from last 8 hours' do
      create(:deployment, :success, environment: environment, created_at: 9.hours.ago)
      create(:deployment, :success, environment: environment, created_at: 7.hours.ago)
      create(:deployment, :success, environment: environment)

      get :index, params: deployment_params(after: 8.hours.ago)

      expect(response).to be_ok

      expect(json_response['deployments'].count).to eq(2)
    end

    it 'returns a list with deployments information' do
      create(:deployment, :success, environment: environment)

      get :index, params: deployment_params

      expect(response).to be_ok
      expect(response).to match_response_schema('deployments')
    end

    context 'anonymous user' do
      let(:anonymous_user) { create(:user) }

      before do
        sign_in(anonymous_user)
      end

      context 'project and metrics dashboard are public' do
        before do
          project.update!(
            visibility_level: Gitlab::VisibilityLevel::PUBLIC,
            project_feature_attributes: {
              metrics_dashboard_access_level: Gitlab::VisibilityLevel::PUBLIC
            }
          )
        end

        it 'returns a list with deployments information' do
          create(:deployment, :success, environment: environment)

          get :index, params: deployment_params

          expect(response).to be_ok
        end
      end

      context 'project and metrics dashboard are private' do
        before do
          project.update!(
            visibility_level: Gitlab::VisibilityLevel::PRIVATE,
            project_feature_attributes: {
              metrics_dashboard_access_level: Gitlab::VisibilityLevel::PRIVATE
            }
          )
        end

        it 'responds with not found' do
          create(:deployment, :success, environment: environment)

          get :index, params: deployment_params

          expect(response).to be_not_found
        end
      end
    end
  end

  describe 'GET #show' do
    render_views

    let(:deployment) { create(:deployment, :success, environment: environment) }

    subject do
      get :show, params: deployment_params(id: deployment.iid)
    end

    context 'as maintainer' do
      it 'renders show with 200 status code' do
        is_expected.to have_gitlab_http_status(:ok)
        is_expected.to render_template(:show)
      end
    end

    context 'as anonymous user' do
      let(:anonymous_user) { create(:user) }

      before do
        sign_in(anonymous_user)
      end

      it 'renders a 404' do
        is_expected.to have_gitlab_http_status(:not_found)
      end
    end
  end

  def deployment_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace, project_id: project, environment_id: environment.id)
  end
end
