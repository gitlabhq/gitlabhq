# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Analytics::CycleAnalytics::SummaryController do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:params) { { namespace_id: project.namespace.to_param, project_id: project.to_param, created_after: '2010-01-01', created_before: '2010-01-02' } }

  before do
    sign_in(user)
  end

  describe 'GET "show"' do
    subject { get :show, params: params }

    it 'succeeds' do
      project.add_reporter(user)

      subject

      expect(response).to be_successful
      expect(response).to match_response_schema('analytics/cycle_analytics/summary')
    end

    context 'when analytics_disabled features are disabled' do
      it 'renders 404' do
        project.add_reporter(user)
        project.project_feature.update!(analytics_access_level: ProjectFeature::DISABLED)

        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is not part of the project' do
      it 'renders 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
