# frozen_string_literal: true

require 'spec_helper'

describe Mutations::Todos::MarkDone do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:author) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let_it_be(:todo1) { create(:todo, user: current_user, author: author, state: :pending) }
  let_it_be(:todo2) { create(:todo, user: current_user, author: author, state: :done) }

  let_it_be(:other_user_todo) { create(:todo, user: other_user, author: author, state: :pending) }

  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }) }

  describe '#resolve' do
    it 'marks a single todo as done' do
      result = mark_done_mutation(todo1)

      expect(todo1.reload.state).to eq('done')
      expect(todo2.reload.state).to eq('done')
      expect(other_user_todo.reload.state).to eq('pending')

      todo = result[:todo]
      expect(todo.id).to eq(todo1.id)
      expect(todo.state).to eq('done')
    end

    it 'handles a todo which is already done as expected' do
      result = mark_done_mutation(todo2)

      expect(todo1.reload.state).to eq('pending')
      expect(todo2.reload.state).to eq('done')
      expect(other_user_todo.reload.state).to eq('pending')

      todo = result[:todo]
      expect(todo.id).to eq(todo2.id)
      expect(todo.state).to eq('done')
    end

    it 'ignores requests for todos which do not belong to the current user' do
      expect { mark_done_mutation(other_user_todo) }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)

      expect(todo1.reload.state).to eq('pending')
      expect(todo2.reload.state).to eq('done')
      expect(other_user_todo.reload.state).to eq('pending')
    end

    it 'ignores invalid GIDs' do
      expect { mutation.resolve(id: 'invalid_gid') }.to raise_error(Gitlab::Graphql::Errors::ArgumentError)

      expect(todo1.reload.state).to eq('pending')
      expect(todo2.reload.state).to eq('done')
      expect(other_user_todo.reload.state).to eq('pending')
    end
  end

  def mark_done_mutation(todo)
    mutation.resolve(id: global_id_of(todo))
  end
end
