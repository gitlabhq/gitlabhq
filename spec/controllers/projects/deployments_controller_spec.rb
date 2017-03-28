require 'spec_helper'

describe Projects::DeploymentsController do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }
  let(:environment) { create(:environment, name: 'production', project: project) }
  let(:deployment) { create(:deployment, project: project, environment: environment) }

  before do
    project.team << [user, :master]

    sign_in(user)
  end

  describe 'GET #index' do
    it 'returns list of deployments withing last 8 hours' do
      create(:deployment, environment: environment, created_at: 9.hours.ago)
      create(:deployment, environment: environment, created_at: 7.hours.ago)
      create(:deployment, environment: environment)

      get :index, environment_params

      expect(response).to be_ok

      expect(json_response['deployments'].count).to eq(2)
    end

    it 'returns a list with deployments information' do
      create(:deployment, environment: environment)

      get :index, environment_params
      expect(response).to be_ok

      deployments = json_response['deployments']
      deployment_info = deployments.first.with_indifferent_access

      expect(deployments.count).to eq(1)
      expect(deployment_info).to include(:id, :iid, :sha, :ref, :tag, :created_at)
    end
  end

  def environment_params(opts={})
    opts.reverse_merge(namespace_id: project.namespace, project_id: project, environment_id: environment.id)
  end
end
