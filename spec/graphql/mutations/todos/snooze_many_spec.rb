# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Todos::SnoozeMany, feature_category: :notifications do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:todo1) { create(:todo, user: user, author: other_user, state: :pending) }
  let_it_be(:todo2) { create(:todo, user: user, author: other_user, state: :pending) }
  let_it_be(:done_todo) { create(:todo, user: user, author: other_user, state: :done) }
  let_it_be(:other_user_todo) { create(:todo, user: other_user, author: user, state: :pending) }

  let(:snooze_until) { 1.day.from_now }
  let(:current_user) { user }

  describe '#process_todos' do
    subject(:mutation) do
      described_class
        .new(object: nil, context: query_context, field: nil)
        .resolve(ids: [
          global_id_of(todo1),
          global_id_of(done_todo),
          global_id_of(other_user_todo)
        ], snooze_until: snooze_until)
    end

    it 'snoozes current user\'s todos matching given ids until given timestamp' do
      expect { mutation }.to change { todo1.reload.snoozed_until }.to be_within(1.second).of(snooze_until)
    end

    it 'does not change other pending todos of the current user' do
      expect { mutation }.not_to change { todo2.reload.snoozed_until }
    end

    it 'does not change done todos' do
      expect { mutation }.not_to change { done_todo.reload.snoozed_until }
    end

    it 'does not change todos of other users' do
      expect { mutation }.not_to change { other_user_todo.reload.snoozed_until }
    end

    it 'returns the ids of processed todos' do
      expect(mutation[:updated_ids]).to contain_exactly(todo1.id)
    end
  end
end
