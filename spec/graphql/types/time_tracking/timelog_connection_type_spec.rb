# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['TimelogConnection'], feature_category: :team_planning do
  it 'has the expected fields' do
    expected_fields = %i[count page_info edges nodes total_spent_time]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  context 'for total_spent_time field' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :empty_repo, :public, group: group) }
    let_it_be(:issue) { create(:issue, project: project) }

    let_it_be(:timelog1) { create(:issue_timelog, issue: issue, time_spent: 1000) }
    let_it_be(:timelog2) { create(:issue_timelog, issue: issue, time_spent: 1500) }
    let_it_be(:timelog3) { create(:issue_timelog, issue: issue, time_spent: 2564) }

    let(:query) do
      %(
        {
          project(fullPath: "#{project.full_path}") {
            timelogs {
              totalSpentTime
            }
          }
        }
      )
    end

    let(:total_spent_time) { subject.dig('data', 'project', 'timelogs', 'totalSpentTime') }

    subject { GitlabSchema.execute(query, context: { current_user: current_user }).as_json }

    context 'when requested' do
      it 'returns the total spent time' do
        expect(total_spent_time).to eq('5064')
      end
    end
  end
end
