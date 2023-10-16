# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Resolvers::ProjectMilestonesResolver' do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:described_class) { Resolvers::ProjectMilestonesResolver }
    let_it_be(:project) { create(:project, :private) }
    let_it_be(:current_user) { create(:user) }
    let_it_be(:now) { Time.now }
    let_it_be(:now_date) { now.to_date }

    before_all do
      project.add_developer(current_user)
    end

    def args(**arguments)
      satisfy("contain only #{arguments.inspect}") do |passed|
        expect(passed.compact).to match(arguments)
      end
    end

    def resolve_project_milestones(args = {}, context = { current_user: current_user })
      resolve(described_class, obj: project, args: args, ctx: context)
    end

    it 'calls MilestonesFinder to retrieve all milestones' do
      expect(MilestonesFinder).to receive(:new)
        .with(args(project_ids: project.id, state: 'all', sort: :due_date_asc))
        .and_call_original

      resolve_project_milestones
    end

    context 'when including ancestor milestones' do
      let(:parent_group) { create(:group) }
      let(:group) { create(:group, parent: parent_group) }
      let(:project) { create(:project, group: group) }

      before do
        project.add_developer(current_user)
      end

      it 'calls MilestonesFinder with correct parameters' do
        expect(MilestonesFinder).to receive(:new).with(
          args(
            project_ids: project.id,
            group_ids: contain_exactly(group, parent_group),
            state: 'all',
            sort: :due_date_asc
          )
        ).and_call_original

        resolve_project_milestones(include_ancestors: true)
      end
    end

    context 'by ids' do
      it 'calls MilestonesFinder with correct parameters' do
        milestone = create(:milestone, project: project)

        expect(MilestonesFinder).to receive(:new)
          .with(args(ids: [milestone.id.to_s], project_ids: project.id, state: 'all', sort: :due_date_asc))
          .and_call_original

        resolve_project_milestones(ids: [milestone.to_global_id])
      end
    end

    context 'by state' do
      it 'calls MilestonesFinder with correct parameters' do
        expect(MilestonesFinder).to receive(:new)
          .with(args(project_ids: project.id, state: 'closed', sort: :due_date_asc))
          .and_call_original

        resolve_project_milestones(state: 'closed')
      end
    end

    context 'by sort' do
      it 'calls MilestonesFinder with correct parameters' do
        expect(MilestonesFinder).to receive(:new)
          .with(args(project_ids: project.id, state: 'all', sort: :due_date_asc))
          .and_call_original

        resolve_project_milestones(sort: 'DUE_DATE_ASC')
      end

      %w[EXPIRED_LAST_DUE_DATE_ASC EXPIRED_LAST_DUE_DATE_DESC].each do |sort_by|
        it "uses offset-pagination when sorting by #{sort_by}" do
          resolved = resolve_project_milestones(sort: sort_by)

          expect(resolved).to be_a(::Gitlab::Graphql::Pagination::OffsetActiveRecordRelationConnection)
        end
      end
    end

    context 'by timeframe' do
      context 'when passing a timeframe' do
        it 'calls MilestonesFinder with correct parameters' do
          start_date = now_date
          end_date = now_date + 5.days

          expect(MilestonesFinder).to receive(:new).with(
            args(
              project_ids: project.id,
              state: 'all',
              sort: :due_date_asc,
              start_date: start_date,
              end_date: end_date
            )
          ).and_call_original

          resolve_project_milestones(timeframe: { start: start_date, end: end_date })
        end
      end
    end

    context 'when title is present' do
      it 'calls MilestonesFinder with correct parameters' do
        expect(MilestonesFinder).to receive(:new)
          .with(args(title: '13.5', state: 'all', sort: :due_date_asc, project_ids: project.id))
          .and_call_original

        resolve_project_milestones(title: '13.5')
      end
    end

    context 'when search_title is present' do
      it 'calls MilestonesFinder with correct parameters' do
        expect(MilestonesFinder).to receive(:new)
          .with(args(search_title: '13', state: 'all', sort: :due_date_asc, project_ids: project.id))
          .and_call_original

        resolve_project_milestones(search_title: '13')
      end
    end

    context 'when containing date is present' do
      it 'calls MilestonesFinder with correct parameters' do
        t = now

        expect(MilestonesFinder).to receive(:new)
          .with(args(containing_date: t, state: 'all', sort: :due_date_asc, project_ids: project.id))
          .and_call_original

        resolve_project_milestones(containing_date: t)
      end
    end
  end
end
