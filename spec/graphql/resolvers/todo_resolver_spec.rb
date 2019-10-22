# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::TodoResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:user) { create(:user) }
    let_it_be(:author1) { create(:user) }
    let_it_be(:author2) { create(:user) }

    let_it_be(:todo1) { create(:todo, user: user, target_type: 'MergeRequest', state: :pending, action: Todo::MENTIONED, author: author1) }
    let_it_be(:todo2) { create(:todo, user: user, state: :done, action: Todo::ASSIGNED, author: author2) }
    let_it_be(:todo3) { create(:todo, user: user, state: :pending, action: Todo::ASSIGNED, author: author1) }

    it 'calls TodosFinder' do
      expect_next_instance_of(TodosFinder) do |finder|
        expect(finder).to receive(:execute)
      end

      resolve_todos
    end

    context 'when using no filter' do
      it 'returns expected todos' do
        todos = resolve(described_class, obj: user, args: {}, ctx: { current_user: user })

        expect(todos).to contain_exactly(todo1, todo3)
      end
    end

    context 'when using filters' do
      # TODO These can be removed as soon as we support filtering for multiple field contents for todos

      it 'just uses the first state' do
        todos = resolve(described_class, obj: user, args: { state: [:done, :pending] }, ctx: { current_user: user })

        expect(todos).to contain_exactly(todo2)
      end

      it 'just uses the first action' do
        todos = resolve(described_class, obj: user, args: { action: [Todo::MENTIONED, Todo::ASSIGNED] }, ctx: { current_user: user })

        expect(todos).to contain_exactly(todo1)
      end

      it 'just uses the first author id' do
        # We need a pending todo for now because of TodosFinder's state query
        todo4 = create(:todo, user: user, state: :pending, action: Todo::ASSIGNED, author: author2)

        todos = resolve(described_class, obj: user, args: { author_id: [author2.id, author1.id] }, ctx: { current_user: user })

        expect(todos).to contain_exactly(todo4)
      end

      it 'just uses the first project id' do
        project1 = create(:project)
        project2 = create(:project)

        create(:todo, project: project1, user: user, state: :pending, action: Todo::ASSIGNED, author: author1)
        todo5 = create(:todo, project: project2, user: user, state: :pending, action: Todo::ASSIGNED, author: author1)

        todos = resolve(described_class, obj: user, args: { project_id: [project2.id, project1.id] }, ctx: { current_user: user })

        expect(todos).to contain_exactly(todo5)
      end

      it 'just uses the first group id' do
        group1 = create(:group)
        group2 = create(:group)

        group1.add_developer(user)
        group2.add_developer(user)

        create(:todo, group: group1, user: user, state: :pending, action: Todo::ASSIGNED, author: author1)
        todo5 = create(:todo, group: group2, user: user, state: :pending, action: Todo::ASSIGNED, author: author1)

        todos = resolve(described_class, obj: user, args: { group_id: [group2.id, group1.id] }, ctx: { current_user: user })

        expect(todos).to contain_exactly(todo5)
      end

      it 'just uses the first target' do
        todos = resolve(described_class, obj: user, args: { type: %w[Issue MergeRequest] }, ctx: { current_user: user })

        # Just todo3 because todo2 is in state "done"
        expect(todos).to contain_exactly(todo3)
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
        todos = resolve(described_class, obj: user, args: {}, ctx: { current_user: current_user })

        expect(todos).to be_empty
      end
    end
  end

  def resolve_todos(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: current_user, args: args, ctx: context)
  end
end
