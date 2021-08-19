# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::TimelogResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :empty_repo, :public, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:error_class) { Gitlab::Graphql::Errors::ArgumentError }

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
      timelogs = resolve_timelogs(**args)

      expect(timelogs).to contain_exactly(timelog1)
    end

    context 'when no dates specified' do
      let(:args) { {} }

      it 'finds all timelogs' do
        timelogs = resolve_timelogs(**args)

        expect(timelogs).to contain_exactly(timelog1, timelog2, timelog3)
      end
    end

    context 'when only start_time present' do
      let(:args) { { start_time: 2.days.ago.noon } }

      it 'finds timelogs after the start_time' do
        timelogs = resolve_timelogs(**args)

        expect(timelogs).to contain_exactly(timelog2)
      end
    end

    context 'when only end_time present' do
      let(:args) { { end_time: 2.days.ago.noon } }

      it 'finds timelogs before the end_time' do
        timelogs = resolve_timelogs(**args)

        expect(timelogs).to contain_exactly(timelog1, timelog3)
      end
    end

    context 'when start_time and end_date are present' do
      let(:args) { { start_time: 6.days.ago, end_date: 2.days.ago } }

      it 'finds timelogs until the end of day of end_date' do
        timelogs = resolve_timelogs(**args)

        expect(timelogs).to contain_exactly(timelog1, timelog2)
      end
    end

    context 'when start_date and end_time are present' do
      let(:args) { { start_date: 6.days.ago, end_time: 2.days.ago.noon } }

      it 'finds all timelogs within start_date and end_time' do
        timelogs = resolve_timelogs(**args)

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

        it 'returns correct error' do
          expect { resolve_timelogs(**args) }
            .to raise_error(error_class, /Provide either a start date or time, but not both/)
        end
      end

      context 'when end_time and end_date are present' do
        let(:args) { { end_time: 2.days.ago, end_date: 2.days.ago } }

        it 'returns correct error' do
          expect { resolve_timelogs(**args) }
            .to raise_error(error_class, /Provide either an end date or time, but not both/)
        end
      end

      context 'when start argument is after end argument' do
        let(:args) { { start_time: 2.days.ago, end_time: 6.days.ago } }

        it 'returns correct error' do
          expect { resolve_timelogs(**args) }
            .to raise_error(error_class, /Start argument must be before End argument/)
        end
      end
    end
  end

  shared_examples "with a group" do
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
      timelogs = resolve_timelogs(**args)

      expect(timelogs).to contain_exactly(timelog1)
    end

    context 'when only start_date is present' do
      let(:args) { { start_date: short_time_ago } }

      it 'finds timelogs until the end of day of end_date' do
        timelogs = resolve_timelogs(**args)

        expect(timelogs).to contain_exactly(timelog1, timelog2)
      end
    end

    context 'when only end_date is present' do
      let(:args) { { end_date: medium_time_ago } }

      it 'finds timelogs until the end of day of end_date' do
        timelogs = resolve_timelogs(**args)

        expect(timelogs).to contain_exactly(timelog3)
      end
    end

    context 'when start_time and end_date are present' do
      let(:args) { { start_time: short_time_ago, end_date: short_time_ago } }

      it 'finds timelogs until the end of day of end_date' do
        timelogs = resolve_timelogs(**args)

        expect(timelogs).to contain_exactly(timelog1, timelog2)
      end
    end

    context 'when start_date and end_time are present' do
      let(:args) { { start_date: short_time_ago, end_time: short_time_ago.noon } }

      it 'finds all timelogs within start_date and end_time' do
        timelogs = resolve_timelogs(**args)

        expect(timelogs).to contain_exactly(timelog1)
      end
    end

    context 'when arguments are invalid' do
      context 'when start_time and start_date are present' do
        let(:args) { { start_time: short_time_ago, start_date: short_time_ago } }

        it 'returns correct error' do
          expect { resolve_timelogs(**args) }
            .to raise_error(error_class, /Provide either a start date or time, but not both/)
        end
      end

      context 'when end_time and end_date are present' do
        let(:args) { { end_time: short_time_ago, end_date: short_time_ago } }

        it 'returns correct error' do
          expect { resolve_timelogs(**args) }
            .to raise_error(error_class, /Provide either an end date or time, but not both/)
        end
      end

      context 'when start argument is after end argument' do
        let(:args) { { start_time: short_time_ago, end_time: medium_time_ago } }

        it 'returns correct error' do
          expect { resolve_timelogs(**args) }
            .to raise_error(error_class, /Start argument must be before End argument/)
        end
      end
    end
  end

  shared_examples "with a user" do
    let_it_be(:short_time_ago) { 5.days.ago.beginning_of_day }
    let_it_be(:medium_time_ago) { 15.days.ago.beginning_of_day }

    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project) }

    let_it_be(:timelog1) { create(:issue_timelog, issue: issue, user: current_user) }
    let_it_be(:timelog2) { create(:issue_timelog, issue: issue, user: create(:user)) }
    let_it_be(:timelog3) { create(:merge_request_timelog, merge_request: merge_request, user: current_user) }

    it 'blah' do
      timelogs = resolve_timelogs(**args)

      expect(timelogs).to contain_exactly(timelog1, timelog3)
    end
  end

  context "on a project" do
    let(:object) { project }
    let(:extra_args) { {} }

    it_behaves_like 'with a project'
  end

  context "with a project filter" do
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

    it_behaves_like 'with a user'
  end

  context 'with a user filter' do
    let(:object) { nil }
    let(:extra_args) { { username: current_user.username } }
    let(:args) { {} }

    it_behaves_like 'with a user'
  end

  context 'when > `default_max_page_size` records' do
    let(:object) { nil }
    let!(:timelog_list) { create_list(:timelog, 101, issue: issue) }
    let(:args) { { project_id: "gid://gitlab/Project/#{project.id}" } }
    let(:extra_args) { {} }

    it 'pagination returns `default_max_page_size` and sets `has_next_page` true' do
      timelogs = resolve_timelogs(**args)

      expect(timelogs.items.count).to be(100)
      expect(timelogs.has_next_page).to be(true)
    end
  end

  context 'when no object or arguments provided' do
    let(:object) { nil }
    let(:args) { {} }
    let(:extra_args) { {} }

    it 'returns correct error' do
      expect { resolve_timelogs(**args) }
        .to raise_error(error_class, /Provide at least one argument/)
    end
  end

  def resolve_timelogs(user: current_user, obj: object, **args)
    context = { current_user: user }
    resolve(described_class, obj: obj, args: args.merge(extra_args), ctx: context)
  end
end
