require 'spec_helper'

describe UsersFinder do
  describe '#execute' do
    let!(:user1) { create(:user, username: 'johndoe') }
    let!(:user2) { create(:user, :blocked, username: 'notsorandom') }
    let!(:external_user) { create(:user, :external) }
    let!(:omniauth_user) { create(:omniauth_user, provider: 'twitter', extern_uid: '123456') }

    context 'with a normal user' do
      let(:user) { create(:user) }

      it 'returns all users' do
        users = described_class.new(user).execute

        expect(users).to contain_exactly(user, user1, user2, omniauth_user)
      end

      it 'filters by username' do
        users = described_class.new(user, username: 'johndoe').execute

        expect(users).to contain_exactly(user1)
      end

      it 'filters by search' do
        users = described_class.new(user, search: 'orando').execute

        expect(users).to contain_exactly(user2)
      end

      it 'filters by blocked users' do
        users = described_class.new(user, blocked: true).execute

        expect(users).to contain_exactly(user2)
      end

      it 'filters by active users' do
        users = described_class.new(user, active: true).execute

        expect(users).to contain_exactly(user, user1, omniauth_user)
      end

      it 'returns no external users' do
        users = described_class.new(user, external: true).execute

        expect(users).to contain_exactly(user, user1, user2, omniauth_user)
      end

      it 'filters by created_at' do
        filtered_user_before = create(:user, created_at: 3.days.ago)
        filtered_user_after = create(:user, created_at: Time.now + 3.days)

        users = described_class.new(user,
                                    created_after: 2.days.ago,
                                    created_before: Time.now + 2.days).execute

        expect(users.map(&:username)).not_to include([filtered_user_before.username, filtered_user_after.username])
      end

      it 'does not filter by custom attributes' do
        users = described_class.new(
          user,
          custom_attributes: { foo: 'bar' }
        ).execute

        expect(users).to contain_exactly(user, user1, user2, omniauth_user)
      end
    end

    context 'with an admin user' do
      let(:admin) { create(:admin) }

      it 'filters by external users' do
        users = described_class.new(admin, external: true).execute

        expect(users).to contain_exactly(external_user)
      end

      it 'returns all users' do
        users = described_class.new(admin).execute

        expect(users).to contain_exactly(admin, user1, user2, external_user, omniauth_user)
      end

      it 'filters by custom attributes' do
        create :user_custom_attribute, user: user1, key: 'foo', value: 'foo'
        create :user_custom_attribute, user: user1, key: 'bar', value: 'bar'
        create :user_custom_attribute, user: user2, key: 'foo', value: 'foo'

        users = described_class.new(
          admin,
          custom_attributes: { foo: 'foo', bar: 'bar' }
        ).execute

        expect(users).to contain_exactly(user1)
      end
    end
  end
end
