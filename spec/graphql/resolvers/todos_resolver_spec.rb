# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::TodosResolver, feature_category: :notifications do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::TodoType.connection_type)
  end

  describe '#resolve' do
    let_it_be(:project) { create(:project) }
    let_it_be(:current_user) { create(:user) }
    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:author1) { create(:user) }
    let_it_be(:author2) { create(:user) }

    let_it_be(:issue_todo_done) { create(:todo, user: current_user, state: :done, action: Todo::ASSIGNED, author: author2, target: issue) }
    let_it_be(:issue_todo_pending) { create(:todo, user: current_user, state: :pending, action: Todo::ASSIGNED, author: author1, target: issue) }

    let(:merge_request) { create(:merge_request, source_project: project) }
    let!(:merge_request_todo_pending) { create(:todo, user: current_user, target: merge_request, state: :pending, action: Todo::MENTIONED, author: author1) }

    before_all do
      project.add_developer(current_user)
    end

    it 'calls TodosFinder' do
      expect_next_instance_of(TodosFinder) do |finder|
        expect(finder).to receive(:execute).and_call_original
      end

      resolve_todos
    end

    context 'when using no filter' do
      it 'returns pending todos' do
        expect(resolve_todos).to contain_exactly(merge_request_todo_pending, issue_todo_pending)
      end
    end

    context 'when using filters' do
      it 'returns the todos for multiple states' do
        todos = resolve_todos(args: { state: [:done, :pending] })

        expect(todos).to contain_exactly(merge_request_todo_pending, issue_todo_done, issue_todo_pending)
      end

      it 'returns the todos for multiple filters' do
        enable_design_management
        design = create(:design, issue: issue)
        design_todo_pending = create(:todo, target: design, user: current_user, state: :pending, action: Todo::ASSIGNED, author: author1)

        todos = resolve_todos(args: { type: ['MergeRequest', 'DesignManagement::Design'] })

        expect(todos).to contain_exactly(merge_request_todo_pending, design_todo_pending)
      end

      it 'returns the todos for single filter' do
        todos = resolve_todos(args: { type: ['MergeRequest'] })

        expect(todos).to contain_exactly(merge_request_todo_pending)
      end

      it 'returns the todos for multiple groups' do
        group1 = create(:group)
        group2 = create(:group)
        group3 = create(:group)

        group1.add_developer(current_user)
        issue1 = create(:issue, project: create(:project, group: group1))
        group2.add_developer(current_user)
        issue2 = create(:issue, project: create(:project, group: group2))
        group3.add_developer(current_user)
        issue3 = create(:issue, project: create(:project, group: group3))

        todo4 = create(:todo, group: group1, user: current_user, state: :pending, action: Todo::ASSIGNED, author: author1, target: issue1)
        todo5 = create(:todo, group: group2, user: current_user, state: :pending, action: Todo::ASSIGNED, author: author1, target: issue2)
        create(:todo, group: group3, user: current_user, state: :pending, action: Todo::ASSIGNED, author: author1, target: issue3)

        todos = resolve_todos(args: { group_id: [group2.id, group1.id] })

        expect(todos).to contain_exactly(todo4, todo5)
      end

      it 'returns the todos for multiple authors' do
        author3 = create(:user)

        create(:todo, user: current_user, state: :pending, action: Todo::ASSIGNED, author: author3)

        todos = resolve_todos(args: { author_id: [author2.id, author1.id] })

        expect(todos).to contain_exactly(merge_request_todo_pending, issue_todo_pending)
      end

      it 'returns the todos for multiple actions' do
        create(:todo, user: current_user, state: :pending, action: Todo::DIRECTLY_ADDRESSED, author: author1)

        todos = resolve_todos(args: { action: [Todo::MENTIONED, Todo::ASSIGNED] })

        expect(todos).to contain_exactly(merge_request_todo_pending, issue_todo_pending)
      end

      it 'returns the todos for multiple projects' do
        project1 = create(:project)
        project2 = create(:project)
        project3 = create(:project)

        project1.add_developer(current_user)
        project2.add_developer(current_user)
        project3.add_developer(current_user)

        todo4 = create(:todo, project: project1, user: current_user, state: :pending, action: Todo::ASSIGNED, author: author1, target: create(:issue, project: project1))
        todo5 = create(:todo, project: project2, user: current_user, state: :pending, action: Todo::ASSIGNED, author: author1, target: create(:issue, project: project2))
        create(:todo, project: project3, user: current_user, state: :pending, action: Todo::ASSIGNED, author: author1, target: create(:issue, project: project3))

        todos = resolve_todos(args: { project_id: [project2.id, project1.id] })

        expect(todos).to contain_exactly(todo4, todo5)
      end

      context 'when filtering by is_snoozed' do
        let_it_be(:new_user) { create(:user) }

        let_it_be(:todo1) { create(:todo, user: new_user, project: project) }
        let_it_be(:todo2) { create(:todo, user: new_user, snoozed_until: 1.month.from_now, project: project) }
        let_it_be(:todo3) { create(:todo, user: new_user, snoozed_until: 1.hour.from_now, project: project) }

        it 'only returns snoozed todos' do
          todos = resolve_todos(args: { is_snoozed: true, sort: 'CREATED_ASC' }, context: { current_user: new_user })

          expect(todos.items).to eq([todo3, todo2])
        end
      end
    end

    context 'when sort is provided' do
      let_it_be(:new_user) { create(:user) }

      let!(:todo1) { create(:todo, user: new_user, project: project, created_at: 5.hours.ago) }
      let!(:todo2) { create(:todo, user: new_user, project: project, created_at: 4.hours.ago) }
      let!(:todo3) { create(:todo, user: new_user, project: project, created_at: 3.hours.ago) }

      it 'sorts in ascendent order' do
        todos = resolve_todos(args: { sort: 'CREATED_ASC' }, context: { current_user: new_user })

        expect(todos.items).to eq([todo1, todo2, todo3])
      end

      it 'sorts in descendent order' do
        todos = resolve_todos(args: { sort: 'CREATED_DESC' }, context: { current_user: new_user })

        expect(todos.items).to eq([todo3, todo2, todo1])
      end
    end

    context 'when no target is provided' do
      it 'returns no todos' do
        todos = resolve(described_class, obj: nil, args: {}, ctx: { current_user: current_user })

        expect(todos).to be_empty
      end
    end

    context 'when target user is not the current user' do
      it 'returns no todos' do
        other_user = create(:user)

        todos = resolve(described_class, obj: other_user, args: {}, ctx: { current_user: current_user })

        expect(todos).to be_empty
      end
    end

    context 'when request is for a todo target' do
      it 'returns only the todos for the target' do
        target = issue_todo_pending.target

        todos = resolve(described_class, obj: target, args: {}, ctx: { current_user: current_user })

        expect(todos).to contain_exactly(issue_todo_pending)
      end
    end
  end

  def resolve_todos(args: {}, context: { current_user: current_user })
    resolve(described_class, obj: context[:current_user], args: args, ctx: context)
  end
end
