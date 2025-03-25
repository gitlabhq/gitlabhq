# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Todos::DeleteMany, feature_category: :notifications do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:author) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let_it_be(:todo1) { create(:todo, user: current_user, author: author, state: :done) }
  let_it_be(:todo2) { create(:todo, user: current_user, author: author, state: :pending) }

  let_it_be(:other_user_todo) { create(:todo, user: other_user, author: author, state: :pending) }

  let(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  describe '#process_todos' do
    context 'when the action is not called too many times' do
      before do
        allow(Gitlab::ApplicationRateLimiter).to(
          receive(:throttled?).with(:bulk_delete_todos, scope: [current_user]).and_return(false)
        )
      end

      it 'deletes a single todo' do
        expect { resolve_mutation([todo1]) }.to change { current_user.todos.count }.by(-1)

        expect(todo2.reload).not_to be_nil
      end

      it 'does not delete a pending todo' do
        result = resolve_mutation([todo2])

        expect(todo2.reload).not_to be_nil

        expect(result).to match(
          errors: be_empty,
          deleted_ids: []
        )
      end

      it 'ignores requests for todos which do not belong to the current user' do
        resolve_mutation([other_user_todo])

        expect(other_user_todo.reload).not_to be_nil
      end

      it 'deletes multiple todos' do
        todo4 = create(:todo, user: current_user, author: author, state: :done)

        expect { resolve_mutation([todo1, todo4, todo2]) }.to change { current_user.todos.count }.by(-2)
      end

      it 'returns ids of the deleted todos' do
        result = resolve_mutation([todo1, todo2])

        expect(result).to match(
          errors: be_empty,
          deleted_ids: [todo1.id]
        )
      end

      it 'skips todo that does not belong to the current user' do
        expect { resolve_mutation([todo1, todo2, other_user_todo]) }.to change { current_user.todos.count }.by(-1)

        expect(other_user_todo.reload).not_to be_nil
      end

      it 'fails if too many todos are requested for update' do
        expect { resolve_mutation([todo1] * 101) }.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
      end
    end

    context 'when the action is called too many times' do
      it 'raises error' do
        expect(Gitlab::ApplicationRateLimiter).to(
          receive(:throttled?).with(:bulk_delete_todos, scope: [current_user]).and_return(true)
        )

        expect do
          resolve_mutation([todo1])
        end.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable, /too many times/)
      end
    end
  end

  def resolve_mutation(todos)
    mutation.resolve(ids: todos.map { |todo| global_id_of(todo) })
  end
end
