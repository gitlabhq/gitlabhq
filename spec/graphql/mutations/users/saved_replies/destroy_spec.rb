# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Users::SavedReplies::Destroy, feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:saved_reply) { create(:saved_reply, user: current_user) }

  let(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  describe '#resolve' do
    subject(:resolve) do
      mutation.resolve(id: saved_reply.to_global_id)
    end

    context 'when service fails to delete a new saved reply' do
      before do
        saved_reply.destroy!
      end

      it 'raises Gitlab::Graphql::Errors::ResourceNotAvailable' do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when service successfully deletes the saved reply' do
      it { expect(resolve[:errors]).to be_empty }
    end
  end
end
