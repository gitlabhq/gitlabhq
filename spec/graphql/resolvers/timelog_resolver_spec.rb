# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::TimelogResolver, feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :empty_repo, :public, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:error_class) { Gitlab::Graphql::Errors::ArgumentError }

  let(:timelogs) { resolve_timelogs(**args) }

  specify do
    expect(described_class).to have_non_null_graphql_type(::Types::TimelogType.connection_type)
  end

  shared_examples_for 'with a project' do
    let_it_be(:merge_request) { create(:merge_request, source_project: project) }
    let_it_be(:timelog1) { create(:issue_timelog, issue: issue, spent_at: 2.days.ago.beginning_of_day) }
    let_it_be(:timelog2) { create(:issue_timelog, issue: issue, spent_at: 2.days.ago.end_of_day) }
    let_it_be(:timelog3) { create(:merge_request_timelog, merge_request: merge_request, spent_at: 10.days.ago) }

    let(:args) { { start_time: 6.days.ago, end_time: 2.days.ago.noon } }

    it 'finds all timelogs within given dates' do
      expect(timelogs).to contain_exactly(timelog1)
    end

    context 'when the project does not exist' do
      let(:extra_args) { { project_id: "gid://gitlab/Project/#{non_existing_record_id}" } }

      it 'returns an empty set' do
        expect(timelogs).to be_empty
      end
    end

    context 'when no dates specified' do
      let(:args) { {} }

      it 'finds all timelogs' do
        expect(timelogs).to contain_exactly(timelog1, timelog2, timelog3)
      end
    end

    context 'when only start_time present' do
      let(:args) { { start_time: 2.days.ago.noon } }

      it 'finds timelogs after the start_time' do
        expect(timelogs).to contain_exactly(timelog2)
      end
    end

    context 'when only end_time present' do
      let(:args) { { end_time: 2.days.ago.noon } }

      it 'finds timelogs before the end_time' do
        expect(timelogs).to contain_exactly(timelog1, timelog3)
      end
    end

    context 'when start_time and end_date are present' do
      let(:args) { { start_time: 6.days.ago, end_date: 2.days.ago } }

      it 'finds timelogs until the end of day of end_date' do
        expect(timelogs).to contain_exactly(timelog1, timelog2)
      end
    end

    context 'when start_date and end_time are present' do
      let(:args) { { start_date: 6.days.ago, end_time: 2.days.ago.noon } }

      it 'finds all timelogs within start_date and end_time' do
        expect(timelogs).to contain_exactly(timelog1)
      end
    end

    it 'return nothing when user has insufficient permissions' do
      project2 = create(:project, :empty_repo, :private)
      issue2 = create(:issue, project: project2)
      create(:issue_timelog, issue: issue2, spent_at: 2.days.ago.beginning_of_day)

      user = create(:user)

      expect(resolve_timelogs(user: user, obj: project2, **args)).to be_empty
    end

    context 'when arguments are invalid' do
      let_it_be(:error_class) { Gitlab::Graphql::Errors::ArgumentError }

      context 'when start_time and start_date are present' do
        let(:args) { { start_time: 6.days.ago, start_date: 6.days.ago } }

        it 'generates an error' do
          expect_graphql_error_to_be_created(error_class, /Provide either a start date or time, but not both/) do
            timelogs
          end
        end
      end

      context 'when end_time and end_date are present' do
        let(:args) { { end_time: 2.days.ago, end_date: 2.days.ago } }

        it 'generates an error' do
          expect_graphql_error_to_be_created(error_class, /Provide either an end date or time, but not both/) do
            timelogs
          end
        end
      end

      context 'when start argument is after end argument' do
        let(:args) { { start_time: 2.days.ago, end_time: 6.days.ago } }

        it 'generates an error' do
          expect_graphql_error_to_be_created(error_class, /Start argument must be before End argument/) do
            timelogs
          end
        end
      end
    end
  end

  shared_examples 'with a group' do
    let_it_be(:short_time_ago) { 5.days.ago.beginning_of_day }
    let_it_be(:medium_time_ago) { 15.days.ago.beginning_of_day }

    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project) }

    let_it_be(:timelog1) { create(:issue_timelog, issue: issue, spent_at: short_time_ago.beginning_of_day) }
    let_it_be(:timelog2) { create(:issue_timelog, issue: issue, spent_at: short_time_ago.end_of_day) }
    let_it_be(:timelog3) { create(:merge_request_timelog, merge_request: merge_request, spent_at: medium_time_ago) }

    let(:args) { { start_time: short_time_ago, end_time: short_time_ago.noon } }

    it 'finds all timelogs' do
      timelogs = resolve_timelogs

      expect(timelogs).to contain_exactly(timelog1, timelog2, timelog3)
    end

    it 'finds all timelogs within given dates' do
      expect(timelogs).to contain_exactly(timelog1)
    end

    context 'when the group does not exist' do
      let_it_be(:error_class) { Gitlab::Graphql::Errors::ResourceNotAvailable }

      let(:extra_args) { { group_id: "gid://gitlab/Group/#{non_existing_record_id}" } }

      it 'returns an error' do
        expect_graphql_error_to_be_created(error_class,
          "The resource that you are attempting to access does not exist or " \
          "you don't have permission to perform this action") do
          timelogs
        end
      end
    end

    context 'when only start_date is present' do
      let(:args) { { start_date: short_time_ago } }

      it 'finds timelogs until the end of day of end_date' do
        expect(timelogs).to contain_exactly(timelog1, timelog2)
      end
    end

    context 'when only end_date is present' do
      let(:args) { { end_date: medium_time_ago } }

      it 'finds timelogs until the end of day of end_date' do
        expect(timelogs).to contain_exactly(timelog3)
      end
    end

    context 'when start_time and end_date are present' do
      let(:args) { { start_time: short_time_ago, end_date: short_time_ago } }

      it 'finds timelogs until the end of day of end_date' do
        expect(timelogs).to contain_exactly(timelog1, timelog2)
      end
    end

    context 'when start_date and end_time are present' do
      let(:args) { { start_date: short_time_ago, end_time: short_time_ago.noon } }

      it 'finds all timelogs within start_date and end_time' do
        expect(timelogs).to contain_exactly(timelog1)
      end
    end

    context 'when arguments are invalid' do
      context 'when start_time and start_date are present' do
        let(:args) { { start_time: short_time_ago, start_date: short_time_ago } }

        it 'generates an error' do
          expect_graphql_error_to_be_created(error_class, /Provide either a start date or time, but not both/) do
            timelogs
          end
        end
      end

      context 'when end_time and end_date are present' do
        let(:args) { { end_time: short_time_ago, end_date: short_time_ago } }

        it 'generates an error' do
          expect_graphql_error_to_be_created(error_class, /Provide either an end date or time, but not both/) do
            timelogs
          end
        end
      end

      context 'when start argument is after end argument' do
        let(:args) { { start_time: short_time_ago, end_time: medium_time_ago } }

        it 'generates an error' do
          expect_graphql_error_to_be_created(error_class, /Start argument must be before End argument/) do
            timelogs
          end
        end
      end
    end
  end

  shared_examples 'with the current user' do
    let_it_be(:short_time_ago) { 5.days.ago.beginning_of_day }
    let_it_be(:medium_time_ago) { 15.days.ago.beginning_of_day }

    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project) }

    let_it_be(:timelog1) { create(:issue_timelog, issue: issue, user: current_user) }
    let_it_be(:timelog2) { create(:issue_timelog, issue: issue, user: create(:user)) }
    let_it_be(:timelog3) { create(:merge_request_timelog, merge_request: merge_request, user: current_user) }

    it 'returns the expected records' do
      if timelogs_found
        expect(timelogs).to contain_exactly(timelog1, timelog3)
      else
        expect(timelogs).to be_empty
      end
    end
  end

  context 'on a project' do
    let(:object) { project }
    let(:extra_args) { {} }

    it_behaves_like 'with a project'
  end

  context 'with a project filter' do
    let(:object) { nil }
    let(:extra_args) { { project_id: project.to_global_id } }

    it_behaves_like 'with a project'
  end

  context 'on a group' do
    let(:object) { group }
    let(:extra_args) { {} }

    it_behaves_like 'with a group'
  end

  context 'with a group filter' do
    let(:object) { nil }
    let(:extra_args) { { group_id: group.to_global_id } }

    it_behaves_like 'with a group'
  end

  context 'on a user' do
    let(:object) { current_user }
    let(:extra_args) { {} }
    let(:args) { {} }
    let(:timelogs_found) { true }

    it_behaves_like 'with the current user'
  end

  context 'with a user filter' do
    let(:object) { nil }
    let(:args) { {} }

    context 'when the user has timelogs' do
      let(:extra_args) { { username: current_user.username } }
      let(:timelogs_found) { true }

      it_behaves_like 'with the current user'
    end

    context 'when the user doest not have timelogs' do
      let(:user) { create(:user) }

      let(:extra_args) { { username: user.username } }
      let(:args) { { user: user } }
      let(:timelogs_found) { false }

      it_behaves_like 'with the current user'
    end
  end

  context 'when no object or arguments provided' do
    let(:object) { nil }
    let(:args) { {} }
    let(:extra_args) { {} }

    it 'generates an error' do
      expect_graphql_error_to_be_created(
        error_class,
        /Non-admin users must provide a group_id, project_id, or current username/
      ) do
        timelogs
      end
    end
  end

  context 'when the sort argument is provided' do
    let_it_be(:timelog_a) do
      create(
        :issue_timelog, time_spent: 7200, spent_at: 1.hour.ago,
        created_at: 1.hour.ago, updated_at: 1.hour.ago, user: current_user
      )
    end

    let_it_be(:timelog_b) do
      create(
        :issue_timelog, time_spent: 5400, spent_at: 2.hours.ago,
        created_at: 2.hours.ago, updated_at: 2.hours.ago, user: current_user
      )
    end

    let_it_be(:timelog_c) do
      create(
        :issue_timelog, time_spent: 1800, spent_at: 30.minutes.ago,
        created_at: 30.minutes.ago, updated_at: 30.minutes.ago, user: current_user
      )
    end

    let_it_be(:timelog_d) do
      create(
        :issue_timelog, time_spent: 3600, spent_at: 1.day.ago,
        created_at: 1.day.ago, updated_at: 1.day.ago, user: current_user
      )
    end

    let(:object) { current_user }
    let(:extra_args) { {} }

    context 'when sort argument comes from TimelogSortEnum' do
      let(:args) { { sort: 'TIME_SPENT_ASC' } }

      it 'returns all the timelogs in the correct order' do
        expect(timelogs.items).to eq([timelog_c, timelog_d, timelog_b, timelog_a])
      end
    end

    context 'when sort argument comes from SortEnum' do
      let(:args) { { sort: 'CREATED_ASC' } }

      it 'returns all the timelogs in the correct order' do
        expect(timelogs.items).to eq([timelog_d, timelog_b, timelog_a, timelog_c])
      end
    end
  end

  def resolve_timelogs(user: current_user, obj: object, **args)
    context = { current_user: user }
    resolve(described_class, obj: obj, args: args.merge(extra_args), ctx: context)
  end
end
