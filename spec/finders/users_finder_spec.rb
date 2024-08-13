# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UsersFinder do
  describe '#execute' do
    include_context 'UsersFinder#execute filter by project context'

    let_it_be(:project_bot) { create(:user, :project_bot) }
    let_it_be(:service_account_user) { create(:user, :service_account, username: 'service_account') }

    shared_examples 'executes users finder as normal user' do
      it 'returns searchable users' do
        users = described_class.new(user).execute

        expect(users).to contain_exactly(user, normal_user, external_user, unconfirmed_user, omniauth_user, internal_user, admin_user, project_bot, service_account_user)
      end

      it 'filters by username' do
        users = described_class.new(user, username: 'johndoe').execute

        expect(users).to contain_exactly(normal_user)
      end

      it 'filters by id' do
        users = described_class.new(user, id: normal_user.id).execute

        expect(users).to contain_exactly(normal_user)
      end

      it 'filters by username (case insensitive)' do
        users = described_class.new(user, username: 'joHNdoE').execute

        expect(users).to contain_exactly(normal_user)
      end

      it 'filters by search' do
        users = described_class.new(user, search: 'ohndo').execute

        expect(users).to contain_exactly(normal_user)
      end

      it 'does not filter by private emails search' do
        users = described_class.new(user, search: normal_user.email).execute

        expect(users).to be_empty
      end

      describe 'minimum character limit for search' do
        it 'passes use_minimum_char_limit from params' do
          search_term = normal_user.username[..1]
          expect(User).to receive(:search)
            .with(search_term, use_minimum_char_limit: false, with_private_emails: anything)
            .once.and_call_original

          described_class.new(user, { search: search_term, use_minimum_char_limit: false }).execute
        end

        it 'allows searching with 2 characters when use_minimum_char_limit is false' do
          users = described_class
                    .new(user, { search: normal_user.username[..1], use_minimum_char_limit: false })
                    .execute

          expect(users).to include(normal_user)
        end

        it 'does not allow searching with 2 characters when use_minimum_char_limit is not set' do
          users = described_class
                    .new(user, search: normal_user.username[..1])
                    .execute

          expect(users).to be_empty
        end
      end

      it 'filters by external users' do
        users = described_class.new(user, external: true).execute

        expect(users).to contain_exactly(external_user)
      end

      it 'filters by non external users' do
        users = described_class.new(user, non_external: true).execute

        expect(users).to contain_exactly(user, normal_user, unconfirmed_user, omniauth_user, internal_user, admin_user, project_bot, service_account_user)
      end

      it 'filters by human users' do
        users = described_class.new(user, humans: true).execute

        expect(users).to contain_exactly(user, normal_user, external_user, unconfirmed_user, omniauth_user, admin_user)
      end

      it 'filters by non-human users' do
        users = described_class.new(user, without_humans: true).execute

        expect(users).to contain_exactly(internal_user, project_bot, service_account_user)
      end

      it 'filters by active users' do
        users = described_class.new(user, active: true).execute

        expect(users).to contain_exactly(user, normal_user, unconfirmed_user, external_user, admin_user, omniauth_user, project_bot, service_account_user)
      end

      it 'filters by non-active users' do
        deactivated_user = create(:user, :deactivated)

        users = described_class.new(user, without_active: true).execute

        expect(users).to contain_exactly(deactivated_user)
      end

      it 'filters by created_at' do
        filtered_user_before = create(:user, created_at: 3.days.ago)
        filtered_user_after = create(:user, created_at: Time.now + 3.days)

        users = described_class.new(
          user,
          created_after: 2.days.ago,
          created_before: Time.now + 2.days
        ).execute

        expect(users.map(&:username)).not_to include([filtered_user_before.username, filtered_user_after.username])
      end

      it 'filters by non internal users' do
        users = described_class.new(user, non_internal: true).execute

        expect(users).to contain_exactly(user, normal_user, unconfirmed_user, external_user, omniauth_user, admin_user, project_bot, service_account_user)
      end

      it 'does not filter by custom attributes' do
        users = described_class.new(
          user,
          custom_attributes: { foo: 'bar' }
        ).execute

        expect(users).to contain_exactly(user, normal_user, external_user, unconfirmed_user, omniauth_user, internal_user, admin_user, project_bot, service_account_user)
      end

      it 'orders returned results' do
        users = described_class.new(user, sort: 'id_asc').execute

        expect(users).to eq([normal_user, admin_user, external_user, unconfirmed_user, omniauth_user, internal_user, project_bot, service_account_user, user])
      end

      it 'does not filter by admins' do
        users = described_class.new(user, admins: true).execute
        expect(users).to contain_exactly(user, normal_user, external_user, admin_user, unconfirmed_user, omniauth_user, internal_user, project_bot, service_account_user)
      end
    end

    shared_examples 'executes users finder as admin' do
      it 'filters by external users' do
        users = described_class.new(user, external: true).execute

        expect(users).to contain_exactly(external_user)
      end

      it 'returns all users' do
        users = described_class.new(user).execute

        expect(users).to contain_exactly(user, normal_user, blocked_user, unconfirmed_user, banned_user, external_user, omniauth_user, internal_user, admin_user, project_bot, service_account_user)
      end

      it 'filters by blocked users' do
        users = described_class.new(user, blocked: true).execute

        expect(users).to contain_exactly(blocked_user)
      end

      it 'filters by active users' do
        users = described_class.new(user, active: true).execute

        expect(users).to contain_exactly(user, normal_user, unconfirmed_user, external_user, omniauth_user, admin_user, project_bot, service_account_user)
      end

      it 'filters by non-active users' do
        users = described_class.new(user, without_active: true).execute

        expect(users).to contain_exactly(banned_user, blocked_user)
      end

      it 'returns only admins' do
        users = described_class.new(user, admins: true).execute

        expect(users).to contain_exactly(user, admin_user)
      end

      it 'filters by custom attributes' do
        create :user_custom_attribute, user: normal_user, key: 'foo', value: 'foo'
        create :user_custom_attribute, user: normal_user, key: 'bar', value: 'bar'
        create :user_custom_attribute, user: blocked_user, key: 'foo', value: 'foo'
        create :user_custom_attribute, user: internal_user, key: 'foo', value: 'foo'

        users = described_class.new(
          user,
          custom_attributes: { foo: 'foo', bar: 'bar' }
        ).execute

        expect(users).to contain_exactly(normal_user)
      end

      it 'filters by private emails search' do
        users = described_class.new(user, search: normal_user.email).execute

        expect(users).to contain_exactly(normal_user)
      end
    end

    context 'with a normal user' do
      let_it_be(:user) { create(:user) }

      it_behaves_like 'executes users finder as normal user'

      context 'with group argument is passed' do
        let_it_be(:group) { create(:group, :private) }
        let_it_be(:subgroup) { create(:group, :private, parent: group) }
        let_it_be(:not_group_member) { create(:user) }

        let_it_be(:indirect_group_member) do
          create(:user, developer_of: subgroup)
        end

        let_it_be(:direct_group_members) do
          [user, omniauth_user, internal_user].each { |u| group.add_developer(u) }
        end

        it 'filtered by search' do
          users = described_class.new(user, group: group).execute
          expect(users).to contain_exactly(indirect_group_member, *direct_group_members)
        end

        context 'when user cannot read group' do
          it 'filtered by search' do
            expect { described_class.new(not_group_member, group: group).execute }.to raise_error(Gitlab::Access::AccessDeniedError)
          end
        end
      end
    end

    context 'with an admin user' do
      let_it_be(:user) { create(:admin) }

      context 'when admin mode setting is disabled', :do_not_mock_admin_mode_setting do
        it_behaves_like 'executes users finder as admin'
      end

      context 'when admin mode setting is enabled' do
        context 'when in admin mode', :enable_admin_mode do
          it_behaves_like 'executes users finder as admin'
        end

        context 'when not in admin mode' do
          it_behaves_like 'executes users finder as normal user'
        end
      end
    end
  end
end
