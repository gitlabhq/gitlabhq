# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Users::SavedRepliesResolver, feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:saved_reply_c) { create(:saved_reply, user: current_user, name: 'gamma') }
  let_it_be(:saved_reply_a) { create(:saved_reply, user: current_user, name: 'alpha') }
  let_it_be(:saved_reply_b) { create(:saved_reply, user: current_user, name: 'Beta') }
  let_it_be(:other_saved_reply) { create(:saved_reply, user: other_user, name: 'other') }

  describe '#resolve' do
    context 'when the user queries their own saved replies' do
      it 'returns comment templates ordered by name' do
        expect(resolve_saved_replies(obj: current_user).nodes).to eq([saved_reply_a, saved_reply_b, saved_reply_c])
      end
    end

    context 'when the user queries another user\'s saved replies' do
      it 'returns an empty result' do
        expect(resolve_saved_replies(obj: other_user).nodes).to be_empty
      end
    end

    context 'when the user is unauthenticated' do
      it 'returns nil or an empty result without raising' do
        expect(resolve_saved_replies(context_user: nil, obj: current_user).nodes).to be_empty
      end
    end
  end

  def resolve_saved_replies(context_user: current_user, obj: current_user)
    resolve(described_class, ctx: { current_user: context_user }, obj: obj)
  end
end
