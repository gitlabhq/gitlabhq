# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Todos::UnsnoozeMany, feature_category: :notifications do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:snoozed_todo1) { create(:todo, user: user, author: other_user, snoozed_until: 8.hours.from_now) }
  let_it_be(:snoozed_todo2) { create(:todo, user: user, author: other_user, snoozed_until: 5.days.from_now) }
  let_it_be(:done_todo) { create(:todo, user: user, author: other_user, state: :done) }
  let_it_be(:other_user_snoozed_todo) { create(:todo, user: other_user, author: user, snoozed_until: 1.hour.from_now) }

  let(:current_user) { user }

  describe '#process_todos' do
    subject(:mutation) do
      described_class
        .new(object: nil, context: query_context, field: nil)
        .resolve(ids: [
          global_id_of(snoozed_todo1),
          global_id_of(done_todo),
          global_id_of(other_user_snoozed_todo)
        ])
    end

    it 'unsnoozes current user\'s todos matching given ids until given timestamp' do
      expect { mutation }.to change { snoozed_todo1.reload.snoozed_until }.to be_nil
    end

    it 'does not change other snoozed todos of the current user' do
      expect { mutation }.not_to change { snoozed_todo2.reload.snoozed_until }
    end

    it 'does not change done todos' do
      expect { mutation }.not_to change { done_todo.reload.snoozed_until }
    end

    it 'does not change todos of other users' do
      expect { mutation }.not_to change { other_user_snoozed_todo.reload.snoozed_until }
    end

    it 'returns the ids of processed todos' do
      expect(mutation[:updated_ids]).to contain_exactly(snoozed_todo1.id)
    end
  end
end
