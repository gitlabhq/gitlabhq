# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Todos::DeleteAllDone, feature_category: :notifications do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  describe '#resolve', :freeze_time do
    it 'schedules deleting worker' do
      expect(::Todos::DeleteAllDoneWorker).to receive(:perform_async)
                                                .with(current_user.id, Time.now.utc.to_datetime.to_s)

      mutation.resolve
    end

    context 'when the action is called too many times' do
      it 'raises error' do
        expect(Gitlab::ApplicationRateLimiter).to(
          receive(:throttled?).with(:delete_all_todos, scope: [current_user]).and_return(true)
        )

        expect do
          mutation.resolve
        end.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable, /too many times/)
      end
    end
  end
end
