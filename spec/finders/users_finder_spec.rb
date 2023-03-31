# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UsersFinder do
  describe '#execute' do
    include_context 'UsersFinder#execute filter by project context'

    let_it_be(:project_bot) { create(:user, :project_bot) }

    shared_examples 'executes users finder as normal user' do
      it 'returns searchable users' do
        users = described_class.new(user).execute

        expect(users).to contain_exactly(user, normal_user, external_user, unconfirmed_user, omniauth_user, internal_user, admin_user, project_bot)
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

      it 'filters by external users' do
        users = described_class.new(user, external: true).execute

        expect(users).to contain_exactly(external_user)
      end

      it 'filters by non external users' do
        users = described_class.new(user, non_external: true).execute

        expect(users).to contain_exactly(user, normal_user, unconfirmed_user, omniauth_user, internal_user, admin_user, project_bot)
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

        expect(users).to contain_exactly(user, normal_user, unconfirmed_user, external_user, omniauth_user, admin_user, project_bot)
      end

      it 'does not filter by custom attributes' do
        users = described_class.new(
          user,
          custom_attributes: { foo: 'bar' }
        ).execute

        expect(users).to contain_exactly(user, normal_user, external_user, unconfirmed_user, omniauth_user, internal_user, admin_user, project_bot)
      end

      it 'orders returned results' do
        users = described_class.new(user, sort: 'id_asc').execute

        expect(users).to eq([normal_user, admin_user, external_user, unconfirmed_user, omniauth_user, internal_user, project_bot, user])
      end

      it 'does not filter by admins' do
        users = described_class.new(user, admins: true).execute
        expect(users).to contain_exactly(user, normal_user, external_user, admin_user, unconfirmed_user, omniauth_user, internal_user, project_bot)
      end
    end

    shared_examples 'executes users finder as admin' do
      it 'filters by external users' do
        users = described_class.new(user, external: true).execute

        expect(users).to contain_exactly(external_user)
      end

      it 'returns all users' do
        users = described_class.new(user).execute

        expect(users).to contain_exactly(user, normal_user, blocked_user, unconfirmed_user, banned_user, external_user, omniauth_user, internal_user, admin_user, project_bot)
      end

      it 'filters by blocked users' do
        users = described_class.new(user, blocked: true).execute

        expect(users).to contain_exactly(blocked_user)
      end

      it 'filters by active users' do
        users = described_class.new(user, active: true).execute

        expect(users).to contain_exactly(user, normal_user, unconfirmed_user, external_user, omniauth_user, admin_user, project_bot)
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
