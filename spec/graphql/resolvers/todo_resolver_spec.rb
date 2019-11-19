# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::TodoResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:author1) { create(:user) }
    let_it_be(:author2) { create(:user) }

    let_it_be(:todo1) { create(:todo, user: current_user, target_type: 'MergeRequest', state: :pending, action: Todo::MENTIONED, author: author1) }
    let_it_be(:todo2) { create(:todo, user: current_user, state: :done, action: Todo::ASSIGNED, author: author2) }
    let_it_be(:todo3) { create(:todo, user: current_user, state: :pending, action: Todo::ASSIGNED, author: author1) }

    it 'calls TodosFinder' do
      expect_next_instance_of(TodosFinder) do |finder|
        expect(finder).to receive(:execute)
      end

      resolve_todos
    end

    context 'when using no filter' do
      it 'returns expected todos' do
        expect(resolve_todos).to contain_exactly(todo1, todo3)
      end
    end

    context 'when using filters' do
      it 'returns the todos for multiple states' do
        todos = resolve_todos({ state: [:done, :pending] })

        expect(todos).to contain_exactly(todo1, todo2, todo3)
      end

      it 'returns the todos for multiple types' do
        todos = resolve_todos({ type: %w[Issue MergeRequest] })

        expect(todos).to contain_exactly(todo1, todo3)
      end

      it 'returns the todos for multiple groups' do
        group1 = create(:group)
        group2 = create(:group)
        group3 = create(:group)

        group1.add_developer(current_user)
        group2.add_developer(current_user)

        todo4 = create(:todo, group: group1, user: current_user, state: :pending, action: Todo::ASSIGNED, author: author1)
        todo5 = create(:todo, group: group2, user: current_user, state: :pending, action: Todo::ASSIGNED, author: author1)
        create(:todo, group: group3, user: current_user, state: :pending, action: Todo::ASSIGNED, author: author1)

        todos = resolve_todos({ group_id: [group2.id, group1.id] })

        expect(todos).to contain_exactly(todo4, todo5)
      end

      it 'returns the todos for multiple authors' do
        author3 = create(:user)

        todo4 = create(:todo, user: current_user, state: :pending, action: Todo::ASSIGNED, author: author2)
        create(:todo, user: current_user, state: :pending, action: Todo::ASSIGNED, author: author3)

        todos = resolve_todos({ author_id: [author2.id, author1.id] })

        expect(todos).to contain_exactly(todo1, todo3, todo4)
      end

      it 'returns the todos for multiple actions' do
        create(:todo, user: current_user, state: :pending, action: Todo::DIRECTLY_ADDRESSED, author: author1)

        todos = resolve_todos({ action: [Todo::MENTIONED, Todo::ASSIGNED] })

        expect(todos).to contain_exactly(todo1, todo3)
      end

      it 'returns the todos for multiple projects' do
        project1 = create(:project)
        project2 = create(:project)
        project3 = create(:project)

        todo4 = create(:todo, project: project1, user: current_user, state: :pending, action: Todo::ASSIGNED, author: author1)
        todo5 = create(:todo, project: project2, user: current_user, state: :pending, action: Todo::ASSIGNED, author: author1)
        create(:todo, project: project3, user: current_user, state: :pending, action: Todo::ASSIGNED, author: author1)

        todos = resolve_todos({ project_id: [project2.id, project1.id] })

        expect(todos).to contain_exactly(todo4, todo5)
      end
    end

    context 'when no user is provided' do
      it 'returns no todos' do
        todos = resolve(described_class, obj: nil, args: {}, ctx: { current_user: current_user })

        expect(todos).to be_empty
      end
    end

    context 'when provided user is not current user' do
      it 'returns no todos' do
        other_user = create(:user)

        todos = resolve(described_class, obj: other_user, args: {}, ctx: { current_user: current_user })

        expect(todos).to be_empty
      end
    end
  end

  def resolve_todos(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: current_user, args: args, ctx: context)
  end
end
