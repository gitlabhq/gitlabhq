# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::GroupMilestonesResolver, feature_category: :team_planning do
  using RSpec::Parameterized::TableSyntax
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:current_user) { create(:user) }

    def resolve_group_milestones(args: {}, context: { current_user: current_user }, arg_style: :internal)
      resolve(described_class, obj: group, args: args, ctx: context, arg_style: arg_style)
    end

    let_it_be(:now) { Time.now }
    let_it_be(:group) { create(:group, :private) }

    def args(**arguments)
      satisfy("contain only #{arguments.inspect}") do |passed|
        expect(passed.compact).to match(arguments)
      end
    end

    before_all do
      group.add_developer(current_user)
    end

    it 'calls MilestonesFinder#execute' do
      expect_next_instance_of(MilestonesFinder) do |finder|
        expect(finder).to receive(:execute)
      end

      resolve_group_milestones
    end

    context 'without parameters' do
      it 'calls MilestonesFinder to retrieve all milestones' do
        expect(MilestonesFinder).to receive(:new)
          .with(args(group_ids: group.id, state: 'all'))
          .and_call_original

        resolve_group_milestones
      end
    end

    context 'with parameters' do
      it 'timeframe argument' do
        start_date = now
        end_date = start_date + 1.hour

        expect(MilestonesFinder).to receive(:new)
          .with(args(group_ids: group.id, state: 'closed', start_date: start_date, end_date: end_date))
          .and_call_original

        resolve_group_milestones(args: { timeframe: { start: start_date, end: end_date }, state: 'closed' })
      end
    end

    context 'by ids' do
      it 'calls MilestonesFinder with correct parameters' do
        milestone = create(:milestone, group: group)

        expect(MilestonesFinder).to receive(:new)
          .with(args(ids: [milestone.id.to_s], group_ids: group.id, state: 'all'))
          .and_call_original

        resolve_group_milestones(args: { ids: [milestone.to_global_id] })
      end
    end

    context 'by sort' do
      it 'calls MilestonesFinder with correct parameters' do
        expect(MilestonesFinder).to receive(:new)
          .with(args(group_ids: group.id, state: 'all', sort: :due_date_desc))
          .and_call_original

        resolve_group_milestones(args: { sort: :due_date_desc })
      end

      %i[expired_last_due_date_asc expired_last_due_date_desc].each do |sort_by|
        it "uses offset-pagination when sorting by #{sort_by}" do
          resolved = resolve_group_milestones(args: { sort: sort_by })

          expect(resolved).to be_a(::Gitlab::Graphql::Pagination::OffsetActiveRecordRelationConnection)
        end
      end
    end

    context 'by timeframe' do
      context 'when timeframe start and end are present' do
        context 'when start is after end' do
          it 'raises error' do
            expect_graphql_error_to_be_created(::Gitlab::Graphql::Errors::ArgumentError, 'start must be before end') do
              resolve_group_milestones(
                args: { timeframe: { start: now.to_date, end: now.to_date - 2.days } },
                arg_style: :internal_prepared
              )
            end
          end
        end
      end
    end

    context 'when including descendant milestones in a public group' do
      let_it_be(:group) { create(:group, :public) }

      let(:args) { { include_descendants: true } }

      it 'finds milestones only in accessible projects and groups' do
        accessible_group = create(:group, :private, parent: group)
        accessible_project = create(:project, group: accessible_group)
        accessible_group.add_developer(current_user)
        inaccessible_group = create(:group, :private, parent: group)
        inaccessible_project = create(:project, :private, group: group)
        milestone1 = create(:milestone, group: group)
        milestone2 = create(:milestone, group: accessible_group)
        milestone3 = create(:milestone, project: accessible_project)
        create(:milestone, group: inaccessible_group)
        create(:milestone, project: inaccessible_project)

        expect(resolve_group_milestones(args: args)).to match_array([milestone1, milestone2, milestone3])
      end
    end

    describe 'include_descendants and include_ancestors' do
      let_it_be(:parent_group) { create(:group, :public) }
      let_it_be(:group) { create(:group, :public, parent: parent_group) }
      let_it_be(:accessible_group) { create(:group, :private, parent: group) }
      let_it_be(:accessible_project) { create(:project, group: accessible_group) }
      let_it_be(:inaccessible_group) { create(:group, :private, parent: group) }
      let_it_be(:inaccessible_project) { create(:project, :private, group: group) }
      let_it_be(:milestone1) { create(:milestone, group: group) }
      let_it_be(:milestone2) { create(:milestone, group: accessible_group) }
      let_it_be(:milestone3) { create(:milestone, project: accessible_project) }
      let_it_be(:milestone4) { create(:milestone, group: inaccessible_group) }
      let_it_be(:milestone5) { create(:milestone, project: inaccessible_project) }
      let_it_be(:milestone6) { create(:milestone, group: parent_group) }

      before do
        accessible_group.add_developer(current_user)
      end

      context 'when including neither ancestor or descendant milestones in a public group' do
        let(:args) { {} }

        it 'finds milestones only in accessible projects and groups' do
          expect(resolve_group_milestones(args: args)).to match_array([milestone1])
        end
      end

      context 'when including descendant milestones in a public group' do
        let(:args) { { include_descendants: true } }

        it 'finds milestones only in accessible projects and groups' do
          expect(resolve_group_milestones(args: args)).to match_array([milestone1, milestone2, milestone3])
        end
      end

      context 'when including ancestor milestones in a public group' do
        let(:args) { { include_ancestors: true } }

        it 'finds milestones only in accessible projects and groups' do
          expect(resolve_group_milestones(args: args)).to match_array([milestone1, milestone6])
        end
      end

      context 'when including both ancestor or descendant milestones in a public group' do
        let(:args) { { include_descendants: true, include_ancestors: true } }

        it 'finds milestones only in accessible projects and groups' do
          expect(resolve_group_milestones(args: args)).to match_array([milestone1, milestone2, milestone3, milestone6])
        end
      end
    end
  end
end
