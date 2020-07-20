# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Todos::RestoreMany do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:author) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let_it_be(:todo1) { create(:todo, user: current_user, author: author, state: :done) }
  let_it_be(:todo2) { create(:todo, user: current_user, author: author, state: :pending) }

  let_it_be(:other_user_todo) { create(:todo, user: other_user, author: author, state: :done) }

  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }

  describe '#resolve' do
    it 'restores a single todo' do
      result = restore_mutation([todo1])

      expect(todo1.reload.state).to eq('pending')
      expect(todo2.reload.state).to eq('pending')
      expect(other_user_todo.reload.state).to eq('done')

      todo_ids = result[:updated_ids]
      expect(todo_ids.size).to eq(1)
      expect(todo_ids.first).to eq(todo1.to_global_id.to_s)

      expect(result[:todos]).to contain_exactly(todo1)
    end

    it 'handles a todo which is already pending as expected' do
      result = restore_mutation([todo2])

      expect_states_were_not_changed

      expect(result[:updated_ids]).to eq([])
      expect(result[:todos]).to be_empty
    end

    it 'ignores requests for todos which do not belong to the current user' do
      restore_mutation([other_user_todo])

      expect_states_were_not_changed
    end

    it 'ignores invalid GIDs' do
      expect { mutation.resolve(ids: ['invalid_gid']) }.to raise_error(URI::BadURIError)

      expect_states_were_not_changed
    end

    it 'restores multiple todos' do
      todo4 = create(:todo, user: current_user, author: author, state: :done)

      result = restore_mutation([todo1, todo4, todo2])

      expect(result[:updated_ids].size).to eq(2)

      returned_todo_ids = result[:updated_ids]
      expect(returned_todo_ids).to contain_exactly(todo1.to_global_id.to_s, todo4.to_global_id.to_s)
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
      expect { restore_mutation([todo1] * 51) }.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
    end

    it 'does not update todos from another app' do
      todo4 = create(:todo)
      todo4_gid = ::URI::GID.parse("gid://otherapp/Todo/#{todo4.id}")

      result = mutation.resolve(ids: [todo4_gid.to_s])

      expect(result[:updated_ids]).to be_empty

      expect_states_were_not_changed
    end

    it 'does not update todos from another model' do
      todo4 = create(:todo)
      todo4_gid = ::URI::GID.parse("gid://#{GlobalID.app}/Project/#{todo4.id}")

      result = mutation.resolve(ids: [todo4_gid.to_s])

      expect(result[:updated_ids]).to be_empty

      expect_states_were_not_changed
    end
  end

  def restore_mutation(todos)
    mutation.resolve(ids: todos.map { |todo| global_id_of(todo) } )
  end

  def global_id_of(todo)
    todo.to_global_id.to_s
  end

  def expect_states_were_not_changed
    expect(todo1.reload.state).to eq('done')
    expect(todo2.reload.state).to eq('pending')
    expect(other_user_todo.reload.state).to eq('done')
  end
end
