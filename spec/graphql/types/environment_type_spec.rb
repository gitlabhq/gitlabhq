# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Environment'] do
  specify { expect(described_class.graphql_name).to eq('Environment') }

  it 'has the expected fields' do
    expected_fields = %w[
      name id state metrics_dashboard latest_opened_most_severe_alert path
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  specify { expect(described_class).to require_graphql_authorizations(:read_environment) }

  context 'when there is an environment' do
    let_it_be(:project) { create(:project) }
    let_it_be(:environment) { create(:environment, project: project) }
    let_it_be(:user) { create(:user) }

    subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            environment(name: "#{environment.name}") {
              name
              path
              state
            }
          }
        }
      )
    end

    before do
      project.add_developer(user)
    end

    it 'returns an environment' do
      expect(subject['data']['project']['environment']['name']).to eq(environment.name)
    end

    it 'returns the path to the environment' do
      expect(subject['data']['project']['environment']['path']).to eq(
        Gitlab::Routing.url_helpers.project_environment_path(project, environment)
      )
    end

    context 'when query alert data for the environment' do
      let_it_be(:query) do
        %(
          query {
            project(fullPath: "#{project.full_path}") {
              environment(name: "#{environment.name}") {
                name
                state
                latestOpenedMostSevereAlert {
                  severity
                  title
                  detailsUrl
                  prometheusAlert {
                    humanizedText
                  }
                }
              }
            }
          }
        )
      end

      it 'does not return alert information' do
        expect(subject['data']['project']['environment']['latestOpenedMostSevereAlert']).to be_nil
      end

      context 'when alert is raised on the environment' do
        let!(:prometheus_alert) { create(:prometheus_alert, project: project, environment: environment) }
        let!(:alert) { create(:alert_management_alert, :triggered, :prometheus, project: project, environment: environment, prometheus_alert: prometheus_alert) }

        it 'returns alert information' do
          expect(subject['data']['project']['environment']['latestOpenedMostSevereAlert']['severity']).to eq(alert.severity.upcase)
        end
      end
    end
  end
end
