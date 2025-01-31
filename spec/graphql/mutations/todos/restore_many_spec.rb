# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Todos::RestoreMany do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:author) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let_it_be(:todo1) { create(:todo, user: current_user, author: author, state: :done) }
  let_it_be(:todo2) { create(:todo, user: current_user, author: author, state: :pending) }

  let_it_be(:other_user_todo) { create(:todo, user: other_user, author: author, state: :done) }

  let(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  describe '#process_todos' do
    it 'restores a single todo' do
      result = restore_mutation([todo1])

      expect(todo1.reload.state).to eq('pending')
      expect(todo2.reload.state).to eq('pending')
      expect(other_user_todo.reload.state).to eq('done')

      expect(result).to match(
        errors: be_empty,
        updated_ids: contain_exactly(todo1.id),
        todos: contain_exactly(todo1)
      )
    end

    it 'handles a todo which is already pending as expected' do
      result = restore_mutation([todo2])

      expect_states_were_not_changed

      expect(result).to match(
        errors: be_empty,
        updated_ids: be_empty,
        todos: be_empty
      )
    end

    it 'ignores requests for todos which do not belong to the current user' do
      restore_mutation([other_user_todo])

      expect_states_were_not_changed
    end

    it 'restores multiple todos' do
      todo4 = create(:todo, user: current_user, author: author, state: :done)

      result = restore_mutation([todo1, todo4, todo2])

      expect(result[:updated_ids].size).to eq(2)

      returned_todo_ids = result[:updated_ids]
      expect(returned_todo_ids).to contain_exactly(todo1.id, todo4.id)
      expect(result[:todos]).to contain_exactly(todo1, todo4)

      expect(todo1.reload.state).to eq('pending')
      expect(todo2.reload.state).to eq('pending')
      expect(todo4.reload.state).to eq('pending')
      expect(other_user_todo.reload.state).to eq('done')
    end

    it 'fails if one todo does not belong to the current user' do
      restore_mutation([todo1, todo2, other_user_todo])

      expect(todo1.reload.state).to eq('pending')
      expect(todo2.reload.state).to eq('pending')
      expect(other_user_todo.reload.state).to eq('done')
    end

    it 'fails if too many todos are requested for update' do
      expect { restore_mutation([todo1] * 101) }.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
    end
  end

  def restore_mutation(todos)
    mutation.resolve(ids: todos.map { |todo| global_id_of(todo) })
  end

  def expect_states_were_not_changed
    expect(todo1.reload.state).to eq('done')
    expect(todo2.reload.state).to eq('pending')
    expect(other_user_todo.reload.state).to eq('done')
  end
end
