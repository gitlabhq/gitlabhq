# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Todos::BaseMany, feature_category: :notifications do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:todo1) { create(:todo, user: user, author: other_user, state: :pending) }
  let_it_be(:todo2) { create(:todo, user: user, author: other_user, state: :pending) }
  let_it_be(:other_user_todo) { create(:todo, user: other_user, author: other_user, state: :pending) }

  let(:mutation) { TestTodoManyMutation.new(object: nil, context: query_context, field: nil) }

  before do
    stub_const('TestTodoManyMutation', Class.new(described_class) do
      def process_todos(todos)
        todos.map(&:id)
      end

      def todo_state_to_find
        :pending
      end
    end)
  end

  describe '#resolve' do
    let(:current_user) { user }

    context 'when implemented correctly in subclass' do
      it 'processes todos and returns the expected structure' do
        result = mutation.resolve(ids: [global_id_of(todo1), global_id_of(todo2)])

        expect(result).to match(
          updated_ids: contain_exactly(todo1.id, todo2.id),
          todos: contain_exactly(todo1, todo2),
          errors: be_empty
        )
      end

      it 'handles empty input gracefully' do
        result = mutation.resolve(ids: [])

        expect(result).to match(
          updated_ids: be_empty,
          todos: be_empty,
          errors: be_empty
        )
      end

      it 'ignores todos belonging to other users' do
        result = mutation.resolve(ids: [global_id_of(other_user_todo)])

        expect(result).to match(
          updated_ids: be_empty,
          todos: be_empty,
          errors: be_empty
        )
      end
    end

    context 'when abstract methods are not implemented' do
      it 'raises NotImplementedError for missing process_todos' do
        stub_const('MissingProcessTodosMutation', Class.new(described_class) do
          def todo_state_to_find
            :pending
          end
        end)

        mutation = MissingProcessTodosMutation.new(object: nil, context: query_context, field: nil)
        expect { mutation.resolve(ids: [global_id_of(todo1)]) }
          .to raise_error(NotImplementedError, /must implement #process_todos/)
      end

      it 'raises NotImplementedError for missing todo_state_to_find' do
        stub_const('MissingTodoStateToFindMutation', Class.new(described_class) do
          def process_todos(todos)
            todos.map(&:id)
          end
        end)

        mutation = MissingTodoStateToFindMutation.new(object: nil, context: query_context, field: nil)
        expect { mutation.resolve(ids: [global_id_of(todo1)]) }
          .to raise_error(NotImplementedError, /must implement #todo_state_to_find/)
      end
    end

    context 'when exceeding maximum update amount' do
      it 'raises an error when too many todos are requested' do
        ids = Array.new((described_class::MAX_UPDATE_AMOUNT + 1)) { global_id_of(todo1) }

        expect { mutation.resolve(ids: ids) }
          .to raise_error(Gitlab::Graphql::Errors::ArgumentError, 'Too many to-do items requested.')
      end
    end
  end

  describe '#authorized_find_all_pending_by_current_user' do
    let(:current_user) { user }

    context 'when ids are blank' do
      it 'returns empty relation' do
        result = mutation.resolve(ids: [])

        expect(result[:todos]).to be_empty
      end
    end

    context 'when user is not authenticated' do
      let(:current_user) { nil }

      it 'returns empty relation' do
        result = mutation.resolve(ids: [global_id_of(todo1)])

        expect(result[:todos]).to be_empty
      end
    end
  end
end
