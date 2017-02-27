require 'spec_helper'

describe PersonalAccessTokensFinder do
  describe '#execute' do
    let(:user) { create(:user) }
    let!(:active_personal_access_token) { create(:personal_access_token, user: user) }
    let!(:expired_personal_access_token) { create(:expired_personal_access_token, user: user) }
    let!(:revoked_personal_access_token) { create(:revoked_personal_access_token, user: user) }
    let!(:active_impersonation_token) { create(:impersonation_personal_access_token, user: user, impersonation: true) }
    let!(:expired_impersonation_token) { create(:expired_personal_access_token, user: user, impersonation: true) }
    let!(:revoked_impersonation_token) { create(:revoked_personal_access_token, user: user, impersonation: true) }

    subject { finder.execute }

    describe 'without user' do
      let(:finder) { described_class.new }

      it do
        is_expected.to contain_exactly(active_personal_access_token, active_impersonation_token,
          revoked_personal_access_token, expired_personal_access_token,
          revoked_impersonation_token, expired_impersonation_token)
      end

      describe 'without impersonation' do
        before { finder.params.merge!(impersonation: false) }

        it { is_expected.to contain_exactly(active_personal_access_token, revoked_personal_access_token, expired_personal_access_token) }

        describe 'with active state' do
          before { finder.params.merge!(state: 'active') }

          it { is_expected.to contain_exactly(active_personal_access_token) }
        end

        describe 'with inactive state' do
          before { finder.params.merge!(state: 'inactive') }

          it { is_expected.to contain_exactly(revoked_personal_access_token, expired_personal_access_token) }
        end
      end

      describe 'with impersonation' do
        before { finder.params.merge!(impersonation: true) }

        it { is_expected.to contain_exactly(active_impersonation_token, revoked_impersonation_token, expired_impersonation_token) }

        describe 'with active state' do
          before { finder.params.merge!(state: 'active') }

          it { is_expected.to contain_exactly(active_impersonation_token) }
        end

        describe 'with inactive state' do
          before { finder.params.merge!(state: 'inactive') }

          it { is_expected.to contain_exactly(revoked_impersonation_token, expired_impersonation_token) }
        end
      end

      describe 'with active state' do
        before { finder.params.merge!(state: 'active') }

        it { is_expected.to contain_exactly(active_personal_access_token, active_impersonation_token) }
      end

      describe 'with inactive state' do
        before { finder.params.merge!(state: 'inactive') }

        it do
          is_expected.to contain_exactly(expired_personal_access_token, revoked_personal_access_token,
            expired_impersonation_token, revoked_impersonation_token)
        end
      end

      describe 'with id' do
        subject { finder.execute(id: active_personal_access_token.id) }

        it { is_expected.to eq(active_personal_access_token) }

        describe 'with impersonation' do
          before { finder.params.merge!(impersonation: true) }

          it { is_expected.to be_nil }
        end
      end

      describe 'with token' do
        subject { finder.execute(token: active_personal_access_token.token) }

        it { is_expected.to eq(active_personal_access_token) }

        describe 'with impersonation' do
          before { finder.params.merge!(impersonation: true) }

          it { is_expected.to be_nil }
        end
      end
    end

    describe 'with user' do
      let(:user2) { create(:user) }
      let(:finder) { described_class.new(user: user) }
      let!(:other_user_active_personal_access_token) { create(:personal_access_token, user: user2) }
      let!(:other_user_expired_personal_access_token) { create(:expired_personal_access_token, user: user2) }
      let!(:other_user_revoked_personal_access_token) { create(:revoked_personal_access_token, user: user2) }
      let!(:other_user_active_impersonation_token) { create(:impersonation_personal_access_token, user: user2, impersonation: true) }
      let!(:other_user_expired_impersonation_token) { create(:expired_personal_access_token, user: user2, impersonation: true) }
      let!(:other_user_revoked_impersonation_token) { create(:revoked_personal_access_token, user: user2, impersonation: true) }

      it do
        is_expected.to contain_exactly(active_personal_access_token, active_impersonation_token,
          revoked_personal_access_token, expired_personal_access_token,
          revoked_impersonation_token, expired_impersonation_token)
      end

      describe 'without impersonation' do
        before { finder.params.merge!(impersonation: false) }

        it { is_expected.to contain_exactly(active_personal_access_token, revoked_personal_access_token, expired_personal_access_token) }

        describe 'with active state' do
          before { finder.params.merge!(state: 'active') }

          it { is_expected.to contain_exactly(active_personal_access_token) }
        end

        describe 'with inactive state' do
          before { finder.params.merge!(state: 'inactive') }

          it { is_expected.to contain_exactly(revoked_personal_access_token, expired_personal_access_token) }
        end
      end

      describe 'with impersonation' do
        before { finder.params.merge!(impersonation: true) }

        it { is_expected.to contain_exactly(active_impersonation_token, revoked_impersonation_token, expired_impersonation_token) }

        describe 'with active state' do
          before { finder.params.merge!(state: 'active') }

          it { is_expected.to contain_exactly(active_impersonation_token) }
        end

        describe 'with inactive state' do
          before { finder.params.merge!(state: 'inactive') }

          it { is_expected.to contain_exactly(revoked_impersonation_token, expired_impersonation_token) }
        end
      end

      describe 'with active state' do
        before { finder.params.merge!(state: 'active') }

        it { is_expected.to contain_exactly(active_personal_access_token, active_impersonation_token) }
      end

      describe 'with inactive state' do
        before { finder.params.merge!(state: 'inactive') }

        it do
          is_expected.to contain_exactly(expired_personal_access_token, revoked_personal_access_token,
            expired_impersonation_token, revoked_impersonation_token)
        end
      end

      describe 'with id' do
        subject { finder.execute(id: active_personal_access_token.id) }

        it { is_expected.to eq(active_personal_access_token) }

        describe 'with impersonation' do
          before { finder.params.merge!(impersonation: true) }

          it { is_expected.to be_nil }
        end
      end

      describe 'with token' do
        subject { finder.execute(token: active_personal_access_token.token) }

        it { is_expected.to eq(active_personal_access_token) }

        describe 'with impersonation' do
          before { finder.params.merge!(impersonation: true) }

          it { is_expected.to be_nil }
        end
      end
    end
  end
end
