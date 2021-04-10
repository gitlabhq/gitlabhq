# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::UsersStarredDashboardsFinder do
  describe '#execute' do
    subject(:starred_dashboards) { described_class.new(user: user, project: project, params: params).execute }

    let_it_be(:user) { create(:user) }

    let(:project) { create(:project) }
    let(:dashboard_path) { 'config/prometheus/common_metrics.yml' }
    let(:params) { {} }

    context 'there are no starred dashboard records' do
      it 'returns empty array' do
        expect(starred_dashboards).to be_empty
      end
    end

    context 'with annotation records' do
      let!(:starred_dashboard_1) { create(:metrics_users_starred_dashboard, user: user, project: project) }
      let!(:starred_dashboard_2) { create(:metrics_users_starred_dashboard, user: user, project: project, dashboard_path: dashboard_path) }
      let!(:other_project_dashboard) { create(:metrics_users_starred_dashboard, user: user, dashboard_path: dashboard_path) }
      let!(:other_user_dashboard) { create(:metrics_users_starred_dashboard, project: project, dashboard_path: dashboard_path) }

      context 'user without read access to project' do
        it 'returns empty relation' do
          expect(starred_dashboards).to be_empty
        end
      end

      context 'user with read access to project' do
        before do
          project.add_reporter(user)
        end

        it 'loads starred dashboards' do
          expect(starred_dashboards).to contain_exactly starred_dashboard_1, starred_dashboard_2
        end

        context 'when the dashboard_path filter is present' do
          let(:params) do
            {
              dashboard_path: dashboard_path
            }
          end

          it 'loads filtered starred dashboards' do
            expect(starred_dashboards).to contain_exactly starred_dashboard_2
          end
        end
      end
    end
  end
end
