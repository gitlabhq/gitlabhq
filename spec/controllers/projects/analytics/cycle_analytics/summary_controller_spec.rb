# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Analytics::CycleAnalytics::SummaryController do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:params) { { namespace_id: project.namespace.to_param, project_id: project.to_param, created_after: '2010-01-01', created_before: '2010-02-01' } }

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

    context 'when filters are applied' do
      let_it_be(:author) { create(:user) }
      let_it_be(:milestone) { create(:milestone, title: 'milestone 1', project: project) }
      let_it_be(:issue_with_author) { create(:issue, project: project, author: author, created_at: Date.new(2010, 1, 15)) }
      let_it_be(:issue_with_other_author) { create(:issue, project: project, author: user, created_at: Date.new(2010, 1, 15)) }
      let_it_be(:issue_with_milestone) { create(:issue, project: project, milestone: milestone, created_at: Date.new(2010, 1, 15)) }

      before do
        project.add_reporter(user)
      end

      it 'filters by author username' do
        params[:author_username] = author.username

        subject

        expect(response).to be_successful

        issue_count = json_response.first
        expect(issue_count['value']).to eq('1')
      end

      it 'filters by milestone title' do
        params[:milestone_title] = milestone.title

        subject

        expect(response).to be_successful

        issue_count = json_response.first
        expect(issue_count['value']).to eq('1')
      end
    end
  end
end
