# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::UserResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }

    context 'when neither an ID or a username is provided' do
      it 'raises an ArgumentError' do
        expect { resolve_user }
        .to raise_error(Gitlab::Graphql::Errors::ArgumentError)
      end
    end

    it 'raises an ArgumentError when both an ID and username are provided' do
      expect { resolve_user(id: user.to_global_id, username: user.username) }
        .to raise_error(Gitlab::Graphql::Errors::ArgumentError)
    end

    context 'by username' do
      it 'returns the correct user' do
        expect(
          resolve_user(username: user.username)
        ).to eq(user)
      end
    end

    context 'by ID' do
      it 'returns the correct user' do
        expect(
          resolve_user(id: user.to_global_id)
        ).to eq(user)
      end
    end
  end

  private

  def resolve_user(args = {})
    sync(resolve(described_class, args: args))
  end
end
