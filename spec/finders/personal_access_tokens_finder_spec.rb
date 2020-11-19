# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokensFinder do
  def finder(options = {}, current_user = nil)
    described_class.new(options, current_user)
  end

  describe '#execute' do
    let(:user) { create(:user) }
    let(:params) { {} }
    let(:current_user) { nil }
    let!(:active_personal_access_token) { create(:personal_access_token, user: user) }
    let!(:expired_personal_access_token) { create(:personal_access_token, :expired, user: user) }
    let!(:revoked_personal_access_token) { create(:personal_access_token, :revoked, user: user) }
    let!(:active_impersonation_token) { create(:personal_access_token, :impersonation, user: user) }
    let!(:expired_impersonation_token) { create(:personal_access_token, :expired, :impersonation, user: user) }
    let!(:revoked_impersonation_token) { create(:personal_access_token, :revoked, :impersonation, user: user) }

    subject { finder(params, current_user).execute }

    context 'when current_user is defined' do
      let(:current_user) { create(:admin) }
      let(:params) { { user: user } }

      context 'current_user is allowed to read PATs' do
        it do
          is_expected.to contain_exactly(active_personal_access_token, active_impersonation_token,
                                        revoked_personal_access_token, expired_personal_access_token,
                                        revoked_impersonation_token, expired_impersonation_token)
        end
      end

      context 'current_user is not allowed to read PATs' do
        let(:current_user) { create(:user) }

        it { is_expected.to be_empty }
      end

      context 'when user param is not set' do
        let(:params) { {} }

        it do
          is_expected.to contain_exactly(active_personal_access_token, active_impersonation_token,
                                         revoked_personal_access_token, expired_personal_access_token,
                                         revoked_impersonation_token, expired_impersonation_token)
        end

        context 'when current_user is not an administrator' do
          let(:current_user) { create(:user) }

          it { is_expected.to be_empty }
        end
      end
    end

    describe 'without user' do
      it do
        is_expected.to contain_exactly(active_personal_access_token, active_impersonation_token,
          revoked_personal_access_token, expired_personal_access_token,
          revoked_impersonation_token, expired_impersonation_token)
      end

      describe 'with users' do
        let(:user2) { create(:user) }

        before do
          create(:personal_access_token, user: user2)
          create(:personal_access_token, :expired, user: user2)
          create(:personal_access_token, :revoked, user: user2)
          create(:personal_access_token, :impersonation, user: user2)
          create(:personal_access_token, :expired, :impersonation, user: user2)
          create(:personal_access_token, :revoked, :impersonation, user: user2)

          params[:users] = [user]
        end

        it {
          is_expected.to contain_exactly(active_personal_access_token, active_impersonation_token,
                                         revoked_personal_access_token, expired_personal_access_token,
                                         revoked_impersonation_token, expired_impersonation_token)
        }
      end

      describe 'with sort order' do
        before do
          params[:sort] = 'id_asc'
        end

        it 'sorts records as per the specified sort order' do
          expect(subject).to match_array(PersonalAccessToken.all.order(id: :asc))
        end
      end

      describe 'without impersonation' do
        before do
          params[:impersonation] = false
        end

        it { is_expected.to contain_exactly(active_personal_access_token, revoked_personal_access_token, expired_personal_access_token) }

        describe 'with active state' do
          before do
            params[:state] = 'active'
          end

          it { is_expected.to contain_exactly(active_personal_access_token) }
        end

        describe 'with inactive state' do
          before do
            params[:state] = 'inactive'
          end

          it { is_expected.to contain_exactly(revoked_personal_access_token, expired_personal_access_token) }
        end
      end

      describe 'with impersonation' do
        before do
          params[:impersonation] = true
        end

        it { is_expected.to contain_exactly(active_impersonation_token, revoked_impersonation_token, expired_impersonation_token) }

        describe 'with active state' do
          before do
            params[:state] = 'active'
          end

          it { is_expected.to contain_exactly(active_impersonation_token) }
        end

        describe 'with inactive state' do
          before do
            params[:state] = 'inactive'
          end

          it { is_expected.to contain_exactly(revoked_impersonation_token, expired_impersonation_token) }
        end
      end

      describe 'with active state' do
        before do
          params[:state] = 'active'
        end

        it { is_expected.to contain_exactly(active_personal_access_token, active_impersonation_token) }
      end

      describe 'with inactive state' do
        before do
          params[:state] = 'inactive'
        end

        it do
          is_expected.to contain_exactly(expired_personal_access_token, revoked_personal_access_token,
            expired_impersonation_token, revoked_impersonation_token)
        end
      end

      describe 'with id' do
        subject { finder(params).find_by_id(active_personal_access_token.id) }

        it { is_expected.to eq(active_personal_access_token) }

        describe 'with impersonation' do
          before do
            params[:impersonation] = true
          end

          it { is_expected.to be_nil }
        end
      end

      describe 'with token' do
        subject { finder(params).find_by_token(active_personal_access_token.token) }

        it { is_expected.to eq(active_personal_access_token) }

        describe 'with impersonation' do
          before do
            params[:impersonation] = true
          end

          it { is_expected.to be_nil }
        end
      end
    end

    describe 'with user' do
      let(:user2) { create(:user) }
      let!(:other_user_active_personal_access_token) { create(:personal_access_token, user: user2) }
      let!(:other_user_expired_personal_access_token) { create(:personal_access_token, :expired, user: user2) }
      let!(:other_user_revoked_personal_access_token) { create(:personal_access_token, :revoked, user: user2) }
      let!(:other_user_active_impersonation_token) { create(:personal_access_token, :impersonation, user: user2) }
      let!(:other_user_expired_impersonation_token) { create(:personal_access_token, :expired, :impersonation, user: user2) }
      let!(:other_user_revoked_impersonation_token) { create(:personal_access_token, :revoked, :impersonation, user: user2) }

      before do
        params[:user] = user
      end

      it do
        is_expected.to contain_exactly(active_personal_access_token, active_impersonation_token,
          revoked_personal_access_token, expired_personal_access_token,
          revoked_impersonation_token, expired_impersonation_token)
      end

      describe 'without impersonation' do
        before do
          params[:impersonation] = false
        end

        it { is_expected.to contain_exactly(active_personal_access_token, revoked_personal_access_token, expired_personal_access_token) }

        describe 'with active state' do
          before do
            params[:state] = 'active'
          end

          it { is_expected.to contain_exactly(active_personal_access_token) }
        end

        describe 'with inactive state' do
          before do
            params[:state] = 'inactive'
          end

          it { is_expected.to contain_exactly(revoked_personal_access_token, expired_personal_access_token) }
        end
      end

      describe 'with impersonation' do
        before do
          params[:impersonation] = true
        end

        it { is_expected.to contain_exactly(active_impersonation_token, revoked_impersonation_token, expired_impersonation_token) }

        describe 'with active state' do
          before do
            params[:state] = 'active'
          end

          it { is_expected.to contain_exactly(active_impersonation_token) }
        end

        describe 'with inactive state' do
          before do
            params[:state] = 'inactive'
          end

          it { is_expected.to contain_exactly(revoked_impersonation_token, expired_impersonation_token) }
        end
      end

      describe 'with active state' do
        before do
          params[:state] = 'active'
        end

        it { is_expected.to contain_exactly(active_personal_access_token, active_impersonation_token) }
      end

      describe 'with inactive state' do
        before do
          params[:state] = 'inactive'
        end

        it do
          is_expected.to contain_exactly(expired_personal_access_token, revoked_personal_access_token,
            expired_impersonation_token, revoked_impersonation_token)
        end
      end

      describe 'with active or expired state' do
        before do
          params[:state] = 'active_or_expired'
        end

        it 'includes active tokens' do
          is_expected.to include(active_personal_access_token, active_impersonation_token)
        end

        it 'includes expired tokens' do
          is_expected.to include(expired_personal_access_token, expired_impersonation_token)
        end

        it 'does not include revoked tokens' do
          is_expected.not_to include(revoked_personal_access_token, revoked_impersonation_token)
        end
      end

      describe 'with id' do
        subject { finder(params).find_by_id(active_personal_access_token.id) }

        it { is_expected.to eq(active_personal_access_token) }

        describe 'with impersonation' do
          before do
            params[:impersonation] = true
          end

          it { is_expected.to be_nil }
        end
      end

      describe 'with token' do
        subject { finder(params).find_by_token(active_personal_access_token.token) }

        it { is_expected.to eq(active_personal_access_token) }

        describe 'with impersonation' do
          before do
            params[:impersonation] = true
          end

          it { is_expected.to be_nil }
        end
      end
    end
  end
end
