# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::UsersResolver do
  include GraphqlHelpers

  let_it_be(:user1) { create(:user, name: "SomePerson") }
  let_it_be(:user2) { create(:user, username: "someone123784") }
  let_it_be(:inactive_user) { create(:user, :deactivated, username: "InactivePerson") }
  let_it_be(:bot_user) { create(:user, :bot, username: "Bot") }
  let_it_be(:internal_user) { create(:user, :placeholder, username: "InternalPerson") }
  let_it_be(:service_account_user) { create(:user, :service_account, username: "ServiceAccountPerson") }
  let_it_be(:current_user) { create(:user) }

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::UserType.connection_type)
  end

  describe '#resolve' do
    context 'when no arguments are passed' do
      it 'returns all users' do
        expect(resolve_users).to contain_exactly(
          user1, user2, current_user, service_account_user, bot_user, internal_user, inactive_user
        )
      end
    end

    context 'when both ids and usernames are passed ' do
      it 'generates an error' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError) do
          resolve_users(args: { ids: [user1.to_global_id.to_s], usernames: [user1.username] })
        end
      end
    end

    context 'when a set of IDs is passed' do
      it 'returns those users' do
        expect(
          resolve_users(args: { ids: [user1.to_global_id.to_s, user2.to_global_id.to_s] })
        ).to contain_exactly(user1, user2)
      end
    end

    context 'when a set of usernames is passed' do
      it 'returns those users' do
        expect(
          resolve_users(args: { usernames: [user1.username, user2.username] })
        ).to contain_exactly(user1, user2)
      end
    end

    context 'when admins is true', :enable_admin_mode do
      let(:admin_user) { create(:user, :admin) }

      it 'returns only admins' do
        expect(
          resolve_users(args: { admins: true }, ctx: { current_user: admin_user })
        ).to contain_exactly(admin_user)
      end
    end

    context 'when active is true' do
      it 'returns only active users' do
        expect(
          resolve_users(args: { active: true })
        ).to contain_exactly(user1, user2, service_account_user, current_user)
      end
    end

    context 'when active is false' do
      it 'returns only non-active users' do
        expect(
          resolve_users(args: { active: false })
        ).to contain_exactly(inactive_user)
      end
    end

    context 'when humans is true' do
      it 'returns only human users' do
        expect(
          resolve_users(args: { humans: true })
        ).to contain_exactly(user1, user2, inactive_user, current_user)
      end
    end

    context 'when humans is false' do
      it 'returns only non-human users' do
        expect(
          resolve_users(args: { humans: false })
        ).to contain_exactly(internal_user, bot_user, service_account_user)
      end
    end

    context 'when a search term is passed' do
      it 'returns all users who match', :aggregate_failures do
        expect(resolve_users(args: { search: "some" })).to contain_exactly(user1, user2)
        expect(resolve_users(args: { search: "123784" })).to contain_exactly(user2)
        expect(resolve_users(args: { search: "someperson" })).to contain_exactly(user1)
      end
    end

    context 'when a set of group_id is passed' do
      let_it_be(:group) { create(:group, :private) }
      let_it_be(:subgroup) { create(:group, :private, parent: group) }
      let_it_be(:group_member) { create(:user) }

      let_it_be(:indirect_group_member) do
        create(:user, developer_of: subgroup)
      end

      let_it_be(:direct_group_members) do
        [current_user, user1, group_member].each { |u| group.add_developer(u) }
      end

      it 'returns direct and indirect members of the group' do
        expect(
          resolve_users(args: { group_id: group.to_global_id })
        ).to contain_exactly(indirect_group_member, *direct_group_members)
      end

      it 'raise an no resource not available error if the group do not exist group' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          resolve_users(args: { group_id: "gid://gitlab/Group/#{non_existing_record_id}" })
        end
      end

      context 'when user cannot read group' do
        let(:current_user) { create(:user) }

        it 'raise an no resource not available error the user cannot read the group' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
            resolve_users(args: { group_id: group.to_global_id })
          end
        end
      end
    end

    context 'with anonymous access' do
      let_it_be(:current_user) { nil }

      it 'prohibits search without usernames passed' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          resolve_users
        end
      end

      it 'prohibits search by username' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          resolve_users(args: { usernames: [user1.username] })
        end
      end
    end
  end

  def resolve_users(args: {}, ctx: {})
    resolve(described_class, args: args, ctx: { current_user: current_user }.merge(ctx))
  end
end
