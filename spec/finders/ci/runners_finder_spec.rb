# frozen_string_literal: true

require 'spec_helper'

describe Ci::RunnersFinder do
  context 'admin' do
    let_it_be(:admin) { create(:user, :admin) }

    describe '#execute' do
      context 'with empty params' do
        it 'returns all runners' do
          runner1 = create :ci_runner, active: true
          runner2 = create :ci_runner, active: false

          expect(described_class.new(current_user: admin, params: {}).execute).to match_array [runner1, runner2]
        end
      end

      context 'filter by search term' do
        it 'calls Ci::Runner.search' do
          expect(Ci::Runner).to receive(:search).with('term').and_call_original

          described_class.new(current_user: admin, params: { search: 'term' }).execute
        end
      end

      context 'filter by status' do
        it 'calls the corresponding scope on Ci::Runner' do
          expect(Ci::Runner).to receive(:paused).and_call_original

          described_class.new(current_user: admin, params: { status_status: 'paused' }).execute
        end
      end

      context 'filter by runner type' do
        it 'calls the corresponding scope on Ci::Runner' do
          expect(Ci::Runner).to receive(:project_type).and_call_original

          described_class.new(current_user: admin, params: { type_type: 'project_type' }).execute
        end
      end

      context 'filter by tag_name' do
        it 'calls the corresponding scope on Ci::Runner' do
          expect(Ci::Runner).to receive(:tagged_with).with(%w[tag1 tag2]).and_call_original

          described_class.new(current_user: admin, params: { tag_name: %w[tag1 tag2] }).execute
        end
      end

      context 'sort' do
        context 'without sort param' do
          it 'sorts by created_at' do
            runner1 = create :ci_runner, created_at: '2018-07-12 07:00'
            runner2 = create :ci_runner, created_at: '2018-07-12 08:00'
            runner3 = create :ci_runner, created_at: '2018-07-12 09:00'

            expect(described_class.new(current_user: admin, params: {}).execute).to eq [runner3, runner2, runner1]
          end
        end

        context 'with sort param' do
          it 'sorts by specified attribute' do
            runner1 = create :ci_runner, contacted_at: 1.minute.ago
            runner2 = create :ci_runner, contacted_at: 3.minutes.ago
            runner3 = create :ci_runner, contacted_at: 2.minutes.ago

            expect(described_class.new(current_user: admin, params: { sort: 'contacted_asc' }).execute).to eq [runner2, runner3, runner1]
          end
        end
      end

      context 'paginate' do
        it 'returns the runners for the specified page' do
          stub_const('Ci::RunnersFinder::NUMBER_OF_RUNNERS_PER_PAGE', 1)
          runner1 = create :ci_runner, created_at: '2018-07-12 07:00'
          runner2 = create :ci_runner, created_at: '2018-07-12 08:00'

          expect(described_class.new(current_user: admin, params: { page: 1 }).execute).to eq [runner2]
          expect(described_class.new(current_user: admin, params: { page: 2 }).execute).to eq [runner1]
        end
      end

      context 'non admin user' do
        it 'returns no runners' do
          user = create :user
          create :ci_runner, active: true
          create :ci_runner, active: false

          expect(described_class.new(current_user: user, params: {}).execute).to be_empty
        end
      end

      context 'user is nil' do
        it 'returns no runners' do
          user = nil
          create :ci_runner, active: true
          create :ci_runner, active: false

          expect(described_class.new(current_user: user, params: {}).execute).to be_empty
        end
      end
    end
  end

  context 'group' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:sub_group_1) { create(:group, parent: group) }
    let_it_be(:sub_group_2) { create(:group, parent: group) }
    let_it_be(:sub_group_3) { create(:group, parent: sub_group_1) }
    let_it_be(:sub_group_4) { create(:group, parent: sub_group_3) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:project_2) { create(:project, group: group) }
    let_it_be(:project_3) { create(:project, group: sub_group_1) }
    let_it_be(:project_4) { create(:project, group: sub_group_2) }
    let_it_be(:project_5) { create(:project, group: sub_group_3) }
    let_it_be(:project_6) { create(:project, group: sub_group_4) }
    let_it_be(:runner_group) { create(:ci_runner, :group, contacted_at: 12.minutes.ago) }
    let_it_be(:runner_sub_group_1) { create(:ci_runner, :group, active: false, contacted_at: 11.minutes.ago) }
    let_it_be(:runner_sub_group_2) { create(:ci_runner, :group, contacted_at: 10.minutes.ago) }
    let_it_be(:runner_sub_group_3) { create(:ci_runner, :group, contacted_at: 9.minutes.ago) }
    let_it_be(:runner_sub_group_4) { create(:ci_runner, :group, contacted_at: 8.minutes.ago) }
    let_it_be(:runner_project_1) { create(:ci_runner, :project, contacted_at: 7.minutes.ago, projects: [project])}
    let_it_be(:runner_project_2) { create(:ci_runner, :project, contacted_at: 6.minutes.ago, projects: [project_2])}
    let_it_be(:runner_project_3) { create(:ci_runner, :project, contacted_at: 5.minutes.ago, description: 'runner_project_search', projects: [project, project_2])}
    let_it_be(:runner_project_4) { create(:ci_runner, :project, contacted_at: 4.minutes.ago, projects: [project_3])}
    let_it_be(:runner_project_5) { create(:ci_runner, :project, contacted_at: 3.minutes.ago, tag_list: %w[runner_tag], projects: [project_4])}
    let_it_be(:runner_project_6) { create(:ci_runner, :project, contacted_at: 2.minutes.ago, projects: [project_5])}
    let_it_be(:runner_project_7) { create(:ci_runner, :project, contacted_at: 1.minute.ago, projects: [project_6])}

    let(:params) { {} }

    before do
      group.runners << runner_group
      sub_group_1.runners << runner_sub_group_1
      sub_group_2.runners << runner_sub_group_2
      sub_group_3.runners << runner_sub_group_3
      sub_group_4.runners << runner_sub_group_4
    end

    describe '#execute' do
      subject { described_class.new(current_user: user, group: group, params: params).execute }

      context 'no params' do
        before do
          group.add_owner(user)
        end

        it 'returns all runners' do
          expect(subject).to eq([runner_project_7, runner_project_6, runner_project_5,
                                 runner_project_4, runner_project_3, runner_project_2,
                                 runner_project_1, runner_sub_group_4, runner_sub_group_3,
                                 runner_sub_group_2, runner_sub_group_1, runner_group])
        end
      end

      context 'with sort param' do
        let(:params) { { sort: 'contacted_asc' } }

        before do
          group.add_owner(user)
        end

        it 'sorts by specified attribute' do
          expect(subject).to eq([runner_group, runner_sub_group_1, runner_sub_group_2,
                                 runner_sub_group_3, runner_sub_group_4, runner_project_1,
                                 runner_project_2, runner_project_3, runner_project_4,
                                 runner_project_5, runner_project_6, runner_project_7])
        end
      end

      context 'paginate' do
        using RSpec::Parameterized::TableSyntax

        let(:runners) do
          [[runner_project_7, runner_project_6, runner_project_5],
           [runner_project_4, runner_project_3, runner_project_2],
           [runner_project_1, runner_sub_group_4, runner_sub_group_3],
           [runner_sub_group_2, runner_sub_group_1, runner_group]]
        end

        where(:page, :index) do
          1 | 0
          2 | 1
          3 | 2
          4 | 3
        end

        before do
          stub_const('Ci::RunnersFinder::NUMBER_OF_RUNNERS_PER_PAGE', 3)

          group.add_owner(user)
        end

        with_them do
          let(:params) { { page: page } }

          it 'returns the runners for the specified page' do
            expect(subject).to eq(runners[index])
          end
        end
      end

      context 'filter by search term' do
        let(:params) { { search: 'runner_project_search' } }

        before do
          group.add_owner(user)
        end

        it 'returns correct runner' do
          expect(subject).to eq([runner_project_3])
        end
      end

      context 'filter by status' do
        let(:params) { { status_status: 'paused' } }

        before do
          group.add_owner(user)
        end

        it 'returns correct runner' do
          expect(subject).to eq([runner_sub_group_1])
        end
      end

      context 'filter by tag_name' do
        let(:params) { { tag_name: %w[runner_tag] } }

        before do
          group.add_owner(user)
        end

        it 'returns correct runner' do
          expect(subject).to eq([runner_project_5])
        end
      end

      context 'filter by runner type' do
        let(:params) { { type_type: 'project_type' } }

        before do
          group.add_owner(user)
        end

        it 'returns correct runners' do
          expect(subject).to eq([runner_project_7, runner_project_6,
                                 runner_project_5, runner_project_4,
                                 runner_project_3, runner_project_2, runner_project_1])
        end
      end

      context 'user has no access to runners' do
        where(:user_permission) do
          [:maintainer, :developer, :reporter, :guest]
        end

        with_them do
          before do
            create(:group_member, user_permission, group: group, user: user)
          end

          it 'returns no runners' do
            expect(subject).to be_empty
          end
        end
      end

      context 'user with no access' do
        it 'returns no runners' do
          expect(subject).to be_empty
        end
      end

      context 'user is nil' do
        let_it_be(:user) { nil }

        it 'returns no runners' do
          expect(subject).to be_empty
        end
      end
    end

    describe '#sort_key' do
      subject { described_class.new(current_user: user, group: group, params: params).sort_key }

      context 'no params' do
        it 'returns created_date' do
          expect(subject).to eq('created_date')
        end
      end

      context 'with params' do
        let(:params) { { sort: 'contacted_asc' } }

        it 'returns contacted_asc' do
          expect(subject).to eq('contacted_asc')
        end
      end
    end
  end
end
