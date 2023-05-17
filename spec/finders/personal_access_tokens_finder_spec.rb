# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokensFinder, :enable_admin_mode do
  using RSpec::Parameterized::TableSyntax

  describe '#execute' do
    let(:admin) { create(:admin) }
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:project_bot) { create(:user, :project_bot) }

    let!(:tokens) do
      {
        active: create(:personal_access_token, user: user, name: 'my_pat_1'),
        active_other: create(:personal_access_token, user: other_user, name: 'my_pat_2'),
        expired: create(:personal_access_token, :expired, user: user),
        revoked: create(:personal_access_token, :revoked, user: user),
        active_impersonation: create(:personal_access_token, :impersonation, user: user),
        expired_impersonation: create(:personal_access_token, :expired, :impersonation, user: user),
        revoked_impersonation: create(:personal_access_token, :revoked, :impersonation, user: user),
        bot: create(:personal_access_token, user: project_bot)
      }
    end

    let(:params) { {} }
    let(:current_user) { admin }

    subject { described_class.new(params, current_user).execute }

    describe 'by current user' do
      context 'with no user' do
        let(:current_user) { nil }

        it 'returns all tokens' do
          is_expected.to match_array(tokens.values)
        end
      end

      context 'with admin' do
        let(:current_user) { admin }

        context 'when admin mode setting is disabled', :do_not_mock_admin_mode_setting do
          it 'returns all tokens' do
            is_expected.to match_array(tokens.values)
          end
        end

        context 'when admin mode setting is enabled' do
          context 'when in admin mode', :enable_admin_mode do
            it 'returns all tokens' do
              is_expected.to match_array(tokens.values)
            end
          end

          context 'when not in admin mode' do
            before do
              allow_next_instance_of(Gitlab::Auth::CurrentUserMode) do |current_user_mode|
                allow(current_user_mode).to receive(:admin_mode?).and_return(false)
              end
            end

            it 'returns no tokens' do
              is_expected.to be_empty
            end
          end
        end
      end

      context 'when user can read user personal access tokens' do
        let(:params) { { user: user } }
        let(:current_user) { user }

        it 'returns tokens of user' do
          is_expected.to contain_exactly(*user.personal_access_tokens)
        end
      end

      context 'when user can not read user personal access tokens' do
        let(:params) { { user: other_user } }
        let(:current_user) { user }

        it 'returns no tokens' do
          is_expected.to be_empty
        end
      end
    end

    describe 'by user' do
      where(:by_user, :expected_tokens) do
        nil              | tokens.keys
        ref(:user)       | [:active, :expired, :revoked, :active_impersonation, :expired_impersonation, :revoked_impersonation]
        ref(:other_user) | [:active_other]
        ref(:admin)      | []
      end

      with_them do
        let(:params) { { user: by_user } }

        it 'returns tokens by user' do
          is_expected.to match_array(tokens.values_at(*expected_tokens))
        end
      end
    end

    describe 'by users' do
      where(:by_users, :expected_tokens) do
        nil                         | tokens.keys
        lazy { [user] }             | [:active, :expired, :revoked, :active_impersonation, :expired_impersonation, :revoked_impersonation]
        lazy { [other_user] }       | [:active_other]
        lazy { [user, other_user] } | [:active, :active_other, :expired, :revoked, :active_impersonation, :expired_impersonation, :revoked_impersonation]
        []                          | []
      end

      with_them do
        let(:params) { { users: by_users } }

        it 'returns tokens by users' do
          is_expected.to match_array(tokens.values_at(*expected_tokens))
        end
      end
    end

    describe 'by impersonation' do
      where(:by_impersonation, :expected_tokens) do
        nil       | tokens.keys
        true      | [:active_impersonation, :expired_impersonation, :revoked_impersonation]
        false     | [:active, :active_other, :expired, :revoked, :bot]
        'other'   | tokens.keys
      end

      with_them do
        let(:params) { { impersonation: by_impersonation } }

        it 'returns tokens by impersonation' do
          is_expected.to match_array(tokens.values_at(*expected_tokens))
        end
      end
    end

    describe 'by state' do
      where(:by_state, :expected_tokens) do
        nil        | tokens.keys
        'active'   | [:active, :active_other, :active_impersonation, :bot]
        'inactive' | [:expired, :revoked, :expired_impersonation, :revoked_impersonation]
        'other'    | tokens.keys
      end

      with_them do
        let(:params) { { state: by_state } }

        it 'returns tokens by state' do
          is_expected.to match_array(tokens.values_at(*expected_tokens))
        end
      end
    end

    describe 'by owner type' do
      where(:by_owner_type, :expected_tokens) do
        nil     | tokens.keys
        'human' | [:active, :active_other, :expired, :revoked, :active_impersonation, :expired_impersonation, :revoked_impersonation]
        'other' | tokens.keys
      end

      with_them do
        let(:params) { { owner_type: by_owner_type } }

        it 'returns tokens by owner type' do
          is_expected.to match_array(tokens.values_at(*expected_tokens))
        end
      end
    end

    describe 'by revoked state' do
      where(:by_revoked_state, :expected_tokens) do
        nil   | [:active, :active_other, :expired, :active_impersonation, :expired_impersonation, :bot]
        true  | [:revoked, :revoked_impersonation]
        false | [:active, :active_other, :expired, :active_impersonation, :expired_impersonation, :bot]
      end

      with_them do
        let(:params) { { revoked: by_revoked_state } }

        it 'returns tokens by revoked state' do
          is_expected.to match_array(tokens.values_at(*expected_tokens))
        end
      end
    end

    describe 'by created date' do
      before do
        tokens[:active_other].update!(created_at: 5.days.ago)
      end

      describe 'by created before' do
        where(:by_created_before, :expected_tokens) do
          6.days.ago      | []
          2.days.ago      | [:active_other]
          2.days.from_now | tokens.keys
        end

        with_them do
          let(:params) { { created_before: by_created_before } }

          it 'returns tokens by created before' do
            is_expected.to match_array(tokens.values_at(*expected_tokens))
          end
        end
      end

      describe 'by created after' do
        where(:by_created_after, :expected_tokens) do
          6.days.ago      | tokens.keys
          2.days.ago      | [:active, :expired, :revoked, :active_impersonation, :expired_impersonation, :revoked_impersonation, :bot]
          2.days.from_now | []
        end

        with_them do
          let(:params) { { created_after: by_created_after } }

          it 'returns tokens by created before' do
            is_expected.to match_array(tokens.values_at(*expected_tokens))
          end
        end
      end
    end

    describe 'by last used date' do
      before do
        PersonalAccessToken.update_all(last_used_at: Time.now)
        tokens[:active_other].update!(last_used_at: 5.days.ago)
      end

      describe 'by last used before' do
        where(:by_last_used_before, :expected_tokens) do
          6.days.ago      | []
          2.days.ago      | [:active_other]
          2.days.from_now | tokens.keys
        end

        with_them do
          let(:params) { { last_used_before: by_last_used_before } }

          it 'returns tokens by last used before' do
            is_expected.to match_array(tokens.values_at(*expected_tokens))
          end
        end
      end

      describe 'by last used after' do
        where(:by_last_used_after, :expected_tokens) do
          6.days.ago      | tokens.keys
          2.days.ago      | [:active, :expired, :revoked, :active_impersonation, :expired_impersonation, :revoked_impersonation, :bot]
          2.days.from_now | []
        end

        with_them do
          let(:params) { { last_used_after: by_last_used_after } }

          it 'returns tokens by last used after' do
            is_expected.to match_array(tokens.values_at(*expected_tokens))
          end
        end
      end
    end

    describe 'by search' do
      where(:by_search, :expected_tokens) do
        nil      | tokens.keys
        'my_pat' | [:active, :active_other]
        'other'  | []
      end

      with_them do
        let(:params) { { search: by_search } }

        it 'returns tokens by search' do
          is_expected.to match_array(tokens.values_at(*expected_tokens))
        end
      end
    end

    describe 'sort' do
      where(:sort, :expected_tokens) do
        nil       | tokens.keys
        'id_asc'  | [:active, :active_other, :expired, :revoked, :active_impersonation, :expired_impersonation, :revoked_impersonation, :bot]
        'id_desc' | [:bot, :revoked_impersonation, :expired_impersonation, :active_impersonation, :revoked, :expired, :active_other, :active]
        'other'   | tokens.keys
      end

      with_them do
        let(:params) { { sort: sort } }

        it 'returns ordered tokens' do
          expect(subject.map(&:id)).to eq(tokens.values_at(*expected_tokens).map(&:id))
        end
      end
    end

    describe 'delegates' do
      subject { described_class.new(params, current_user) }

      describe '#find_by_id' do
        it 'returns token by id' do
          expect(subject.find_by_id(tokens[:active].id)).to eq(tokens[:active])
        end
      end

      describe '#find_by_token' do
        it 'returns token by token' do
          expect(subject.find_by_token(tokens[:active].token)).to eq(tokens[:active])
        end
      end

      describe '#find' do
        it 'returns token by id' do
          expect(subject.find(tokens[:active].id)).to eq(tokens[:active])
        end
      end
    end
  end
end
