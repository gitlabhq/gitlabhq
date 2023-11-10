# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::SavedReplyResolver, feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:saved_reply) { create(:saved_reply, user: current_user) }

  it 'returns users saved reply' do
    expect(resolve_saved_reply).to eq(saved_reply)
  end

  it 'returns nil when saved reply is not found' do
    expect(resolve_saved_reply({ id: 'gid://gitlab/Users::SavedReply/100' })).to be_nil
  end

  it 'returns nil when saved reply is another users' do
    other_users_saved_reply = create(:saved_reply, user: create(:user))

    expect(resolve_saved_reply({ id: other_users_saved_reply.to_global_id })).to be_nil
  end

  def resolve_saved_reply(args = { id: saved_reply.to_global_id })
    resolve(described_class, args: args, ctx: { current_user: current_user })
  end
end
