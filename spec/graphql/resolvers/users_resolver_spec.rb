# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::UsersResolver do
  include GraphqlHelpers

  let_it_be(:user1) { create(:user, name: "SomePerson") }
  let_it_be(:user2) { create(:user, username: "someone123784") }

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::UserType.connection_type)
  end

  describe '#resolve' do
    it 'raises an error when read_users_list is not authorized' do
      expect(Ability).to receive(:allowed?).with(nil, :read_users_list).and_return(false)

      expect { resolve_users }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    context 'when no arguments are passed' do
      it 'returns all users' do
        expect(resolve_users).to contain_exactly(user1, user2)
      end
    end

    context 'when both ids and usernames are passed ' do
      it 'raises an error' do
        expect { resolve_users(ids: [user1.to_global_id.to_s], usernames: [user1.username]) }
        .to raise_error(Gitlab::Graphql::Errors::ArgumentError)
      end
    end

    context 'when a set of IDs is passed' do
      it 'returns those users' do
        expect(
          resolve_users(ids: [user1.to_global_id.to_s, user2.to_global_id.to_s])
        ).to contain_exactly(user1, user2)
      end
    end

    context 'when a set of usernames is passed' do
      it 'returns those users' do
        expect(
          resolve_users(usernames: [user1.username, user2.username])
        ).to contain_exactly(user1, user2)
      end
    end

    context 'when a search term is passed' do
      it 'returns all users who match', :aggregate_failures do
        expect(resolve_users(search: "some")).to contain_exactly(user1, user2)
        expect(resolve_users(search: "123784")).to contain_exactly(user2)
        expect(resolve_users(search: "someperson")).to contain_exactly(user1)
      end
    end
  end

  def resolve_users(args = {})
    resolve(described_class, args: args)
  end
end
