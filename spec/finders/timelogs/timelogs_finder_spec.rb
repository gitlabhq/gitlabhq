# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Timelogs::TimelogsFinder, feature_category: :team_planning do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:group_a) { create(:group) }
  let_it_be(:group_b) { create(:group) }
  let_it_be(:project_a) { create(:project, :empty_repo, :public, group: group_a) }
  let_it_be(:project_b) { create(:project, :empty_repo, :public, group: group_a) }
  let_it_be(:project_c) { create(:project, :empty_repo, :public, group: group_b) }

  let_it_be(:issue_a) { create(:issue, project: project_a) }
  let_it_be(:issue_b) { create(:issue, project: project_b) }
  let_it_be(:issue_c) { create(:issue, project: project_c) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project_a) }

  let_it_be(:timelog1) do
    create(:issue_timelog, issue: issue_a, user: current_user, spent_at: 2.days.ago.beginning_of_day, time_spent: 3000)
  end

  let_it_be(:timelog2) do
    create(:issue_timelog, issue: issue_a, user: create(:user), spent_at: 2.days.ago.end_of_day, time_spent: 4000)
  end

  let_it_be(:timelog3) do
    create(:merge_request_timelog,
      merge_request: merge_request,
      user: current_user,
      spent_at: 10.days.ago,
      time_spent: 2000)
  end

  let_it_be(:timelog4) do
    create(:issue_timelog, issue: issue_b, user: current_user, spent_at: 1.hour.ago, time_spent: 500)
  end

  let_it_be(:timelog5) do
    create(:issue_timelog, issue: issue_c, user: create(:user), spent_at: 7.days.ago.end_of_day, time_spent: 6000)
  end

  subject(:finder_results) { described_class.new(issuable, params).execute }

  describe '#execute' do
    let(:issuable) { nil }
    let(:params) { {} }

    context 'when params is empty' do
      it 'returns all timelogs' do
        expect(finder_results).to contain_exactly(timelog1, timelog2, timelog3, timelog4, timelog5)
      end
    end

    context 'when an issuable is provided' do
      let(:issuable) { issue_a }

      it 'returns the issuable timelogs' do
        expect(finder_results).to contain_exactly(timelog1, timelog2)
      end
    end

    context 'when a username is provided' do
      let(:params) { { username: current_user.username } }

      it 'returns all timelogs created by the user' do
        expect(finder_results).to contain_exactly(timelog1, timelog3, timelog4)
      end
    end

    context 'when a group is provided' do
      let(:params) { { group_id: group_a.id } }

      it 'returns all timelogs of issuables inside that group' do
        expect(finder_results).to contain_exactly(timelog1, timelog2, timelog3, timelog4)
      end

      context 'when the group does not exist' do
        let(:params) { { group_id: non_existing_record_id } }

        it 'raises an exception' do
          expect { finder_results }.to raise_error(
            ActiveRecord::RecordNotFound, /Group with id '\d+' could not be found/)
        end
      end
    end

    context 'when a project is provided' do
      let(:params) { { project_id: project_a.id } }

      it 'returns all timelogs of issuables inside that project' do
        expect(finder_results).to contain_exactly(timelog1, timelog2, timelog3)
      end

      context 'when the project does not exist' do
        let(:params) { { project_id: non_existing_record_id } }

        it 'returns an empty list and does not raise an exception' do
          expect(finder_results).to be_empty
          expect { finder_results }.not_to raise_error
        end
      end
    end

    context 'when a start datetime is provided' do
      let(:params) { { start_time: 3.days.ago.beginning_of_day } }

      it 'returns all timelogs created after that date' do
        expect(finder_results).to contain_exactly(timelog1, timelog2, timelog4)
      end
    end

    context 'when an end datetime is provided' do
      let(:params) { { end_time: 3.days.ago.beginning_of_day } }

      it 'returns all timelogs created before that date' do
        expect(finder_results).to contain_exactly(timelog3, timelog5)
      end
    end

    context 'when both a start and an end datetime are provided' do
      let(:params) { { start_time: 2.days.ago.beginning_of_day, end_time: 1.day.ago.beginning_of_day } }

      it 'returns all timelogs created between those dates' do
        expect(finder_results).to contain_exactly(timelog1, timelog2)
      end

      context 'when start time is after end time' do
        let(:params) { { start_time: 1.day.ago.beginning_of_day, end_time: 2.days.ago.beginning_of_day } }

        it 'raises an exception' do
          expect { finder_results }.to raise_error(ArgumentError, /Start argument must be before End argument/)
        end
      end
    end

    context 'when sort is provided' do
      let(:params) { { sort: sort_value } }

      context 'when sorting by spent_at desc' do
        let(:sort_value) { :spent_at_desc }

        it 'returns timelogs sorted accordingly' do
          expect(finder_results).to eq([timelog4, timelog2, timelog1, timelog5, timelog3])
        end
      end

      context 'when sorting by spent_at asc' do
        let(:sort_value) { :spent_at_asc }

        it 'returns timelogs sorted accordingly' do
          expect(finder_results).to eq([timelog3, timelog5, timelog1, timelog2, timelog4])
        end
      end

      context 'when sorting by time_spent desc' do
        let(:sort_value) { :time_spent_desc }

        it 'returns timelogs sorted accordingly' do
          expect(finder_results).to eq([timelog5, timelog2, timelog1, timelog3, timelog4])
        end
      end

      context 'when sorting by time_spent asc' do
        let(:sort_value) { :time_spent_asc }

        it 'returns timelogs sorted accordingly' do
          expect(finder_results).to eq([timelog4, timelog3, timelog1, timelog2, timelog5])
        end
      end
    end
  end
end
