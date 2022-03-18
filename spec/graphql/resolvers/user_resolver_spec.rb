# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::UserResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }

    context 'when neither an ID or a username is provided' do
      it 'generates an ArgumentError' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError) do
          resolve_user
        end
      end
    end

    it 'generates an ArgumentError when both an ID and username are provided' do
      expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError) do
        resolve_user(id: user.to_global_id, username: user.username)
      end
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
