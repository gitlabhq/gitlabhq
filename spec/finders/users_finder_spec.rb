# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UsersFinder do
  describe '#execute' do
    include_context 'UsersFinder#execute filter by project context'

    context 'with a normal user' do
      let(:user) { create(:user) }

      it 'returns all users' do
        users = described_class.new(user).execute

        expect(users).to contain_exactly(user, normal_user, blocked_user, external_user, omniauth_user, internal_user, admin_user)
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
        users = described_class.new(user, search: 'orando').execute

        expect(users).to contain_exactly(blocked_user)
      end

      it 'filters by blocked users' do
        users = described_class.new(user, blocked: true).execute

        expect(users).to contain_exactly(blocked_user)
      end

      it 'filters by active users' do
        users = described_class.new(user, active: true).execute

        expect(users).to contain_exactly(user, normal_user, external_user, omniauth_user, admin_user)
      end

      it 'filters by external users' do
        users = described_class.new(user, external: true).execute

        expect(users).to contain_exactly(external_user)
      end

      it 'filters by non external users' do
        users = described_class.new(user, non_external: true).execute

        expect(users).to contain_exactly(user, normal_user, blocked_user, omniauth_user, internal_user, admin_user)
      end

      it 'filters by created_at' do
        filtered_user_before = create(:user, created_at: 3.days.ago)
        filtered_user_after = create(:user, created_at: Time.now + 3.days)

        users = described_class.new(user,
                                    created_after: 2.days.ago,
                                    created_before: Time.now + 2.days).execute

        expect(users.map(&:username)).not_to include([filtered_user_before.username, filtered_user_after.username])
      end

      it 'filters by non internal users' do
        users = described_class.new(user, non_internal: true).execute

        expect(users).to contain_exactly(user, normal_user, external_user, blocked_user, omniauth_user, admin_user)
      end

      it 'does not filter by custom attributes' do
        users = described_class.new(
          user,
          custom_attributes: { foo: 'bar' }
        ).execute

        expect(users).to contain_exactly(user, normal_user, blocked_user, external_user, omniauth_user, internal_user, admin_user)
      end

      it 'orders returned results' do
        users = described_class.new(user, sort: 'id_asc').execute

        expect(users).to eq([normal_user, admin_user, blocked_user, external_user, omniauth_user, internal_user, user])
      end

      it 'does not filter by admins' do
        users = described_class.new(user, admins: true).execute
        expect(users).to contain_exactly(user, normal_user, external_user, admin_user, blocked_user, omniauth_user, internal_user)
      end
    end

    context 'with an admin user', :enable_admin_mode do
      let(:admin) { create(:admin) }

      it 'filters by external users' do
        users = described_class.new(admin, external: true).execute

        expect(users).to contain_exactly(external_user)
      end

      it 'returns all users' do
        users = described_class.new(admin).execute

        expect(users).to contain_exactly(admin, normal_user, blocked_user, external_user, omniauth_user, internal_user, admin_user)
      end

      it 'returns only admins' do
        users = described_class.new(admin, admins: true).execute

        expect(users).to contain_exactly(admin, admin_user)
      end

      it 'filters by custom attributes' do
        create :user_custom_attribute, user: normal_user, key: 'foo', value: 'foo'
        create :user_custom_attribute, user: normal_user, key: 'bar', value: 'bar'
        create :user_custom_attribute, user: blocked_user, key: 'foo', value: 'foo'
        create :user_custom_attribute, user: internal_user, key: 'foo', value: 'foo'

        users = described_class.new(
          admin,
          custom_attributes: { foo: 'foo', bar: 'bar' }
        ).execute

        expect(users).to contain_exactly(normal_user)
      end
    end
  end
end
