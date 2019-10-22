# frozen_string_literal: true

require 'spec_helper'

describe MetricsDashboard do
  describe 'GET #metrics_dashboard' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:environment) { create(:environment, project: project) }

    before do
      sign_in(user)
      project.add_maintainer(user)
    end

    controller(::ApplicationController) do
      include MetricsDashboard # rubocop:disable RSpec/DescribedClass
    end

    let(:json_response) do
      routes.draw { get "metrics_dashboard" => "anonymous#metrics_dashboard" }
      response = get :metrics_dashboard, format: :json

      JSON.parse(response.parsed_body)
    end

    context 'when no parameters are provided' do
      it 'returns an error json_response' do
        expect(json_response['status']).to eq('error')
      end
    end

    context 'when params are provided' do
      before do
        allow(controller).to receive(:project).and_return(project)
        allow(controller)
          .to receive(:metrics_dashboard_params)
          .and_return(environment: environment)
      end

      it 'returns the specified dashboard' do
        expect(json_response['dashboard']['dashboard']).to eq('Environment metrics')
        expect(json_response).not_to have_key('all_dashboards')
      end

      context 'when parameters are provided and the list of all dashboards is required' do
        before do
          allow(controller).to receive(:include_all_dashboards?).and_return(true)
        end

        it 'returns a dashboard in addition to the list of dashboards' do
          expect(json_response['dashboard']['dashboard']).to eq('Environment metrics')
          expect(json_response).to have_key('all_dashboards')
        end
      end
    end
  end
end
