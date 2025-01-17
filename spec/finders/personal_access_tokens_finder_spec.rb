# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokensFinder, :enable_admin_mode, feature_category: :system_access do
  using RSpec::Parameterized::TableSyntax

  describe '#execute' do
    let_it_be(:organization) { create(:organization) }
    let_it_be(:admin) { create(:admin, organizations: [organization]) }
    let_it_be(:user) { create(:user, organizations: [organization]) }
    let_it_be(:other_user) { create(:user) }
    let_it_be(:project_bot) { create(:user, :project_bot) }
    let_it_be(:first_organization) { create(:organization) }
    let_it_be(:second_organization) { create(:organization) }

    let_it_be(:tokens) do
      {
        active: create(:personal_access_token, user: user, name: 'my_pat_1', organization: organization),
        active_other: create(:personal_access_token, user: other_user, name: 'my_pat_2', organization: organization),
        expired: create(:personal_access_token, :expired, user: user, organization: organization),
        revoked: create(:personal_access_token, :revoked, user: user, organization: organization),
        active_impersonation: create(:personal_access_token, :impersonation, user: user, organization: organization),
        expired_impersonation: create(:personal_access_token, :expired, :impersonation, user: user, organization: organization),
        revoked_impersonation: create(:personal_access_token, :revoked, :impersonation, user: user, organization: organization),
        bot: create(:personal_access_token, user: project_bot, organization: organization)
      }
    end

    let_it_be(:tokens_from_other_organizations) do
      {
        with_first_organization: create(:personal_access_token, organization: first_organization),
        with_second_organization: create(:personal_access_token, organization: second_organization)
      }
    end

    let_it_be(:all_tokens) { tokens.merge(tokens_from_other_organizations) }

    let(:tokens_keys) { tokens.keys }

    let(:default_params) { { organization: organization } }
    let(:params) { {} }
    let(:current_user) { admin }

    subject { described_class.new(default_params.merge(params), current_user).execute }

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
        nil              | ref(:tokens_keys)
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
        nil                         | ref(:tokens_keys)
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
        nil       | ref(:tokens_keys)
        true      | [:active_impersonation, :expired_impersonation, :revoked_impersonation]
        false     | [:active, :active_other, :expired, :revoked, :bot]
        'other'   | ref(:tokens_keys)
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
        nil        | ref(:tokens_keys)
        'active'   | [:active, :active_other, :active_impersonation, :bot]
        'inactive' | [:expired, :revoked, :expired_impersonation, :revoked_impersonation]
        'other'    | ref(:tokens_keys)
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
        nil     | ref(:tokens_keys)
        'human' | [:active, :active_other, :expired, :revoked, :active_impersonation, :expired_impersonation, :revoked_impersonation]
        'other' | ref(:tokens_keys)
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
          2.days.from_now | ref(:tokens_keys)
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
          6.days.ago      | ref(:tokens_keys)
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

    describe 'by expires before' do
      where(:by_expires_before, :expected_tokens) do
        2.days.ago       | []
        29.days.from_now | [:expired, :expired_impersonation]
        31.days.from_now | ref(:tokens_keys)
      end

      with_them do
        let(:params) { { expires_before: by_expires_before } }

        it 'returns tokens by expires before' do
          is_expected.to match_array(tokens.values_at(*expected_tokens))
        end
      end
    end

    describe 'by expires after' do
      where(:by_expires_after, :expected_tokens) do
        2.days.ago       | ref(:tokens_keys)
        30.days.from_now | [:active, :active_other, :revoked, :active_impersonation, :revoked_impersonation, :bot]
        31.days.from_now | []
      end

      with_them do
        let(:params) { { expires_after: by_expires_after } }

        it 'returns tokens by expires after' do
          is_expected.to match_array(tokens.values_at(*expected_tokens))
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
          2.days.from_now | ref(:tokens_keys)
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
          6.days.ago      | ref(:tokens_keys)
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
        nil      | ref(:tokens_keys)
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

    describe 'by_organization' do
      let(:params) { { organization: first_organization } }

      it 'returns tokens by organization' do
        is_expected.to match_array(PersonalAccessToken.where(organization: first_organization))
      end

      context 'when orgnzation is not specified' do
        let(:params) { { organization: nil } }

        it 'returns empty when organization is not specified' do
          is_expected.to match_array(all_tokens.values)
        end
      end

      context 'when the feature flag pat_organization_filter is disabled' do
        before do
          stub_feature_flags(pat_organization_filter: false)
        end

        let(:params) { { organization: first_organization } }

        it 'returns tokens by organization' do
          is_expected.to match_array(all_tokens.values)
        end
      end
    end

    describe 'sort' do
      where(:sort, :expected_tokens) do
        nil       | ref(:tokens_keys)
        'id_asc'  | [:active, :active_other, :expired, :revoked, :active_impersonation, :expired_impersonation, :revoked_impersonation, :bot]
        'id_desc' | [:bot, :revoked_impersonation, :expired_impersonation, :active_impersonation, :revoked, :expired, :active_other, :active]
        'other'   | ref(:tokens_keys)
      end

      with_them do
        let(:params) { { sort: sort } }

        it 'returns ordered tokens', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/446283' do
          expect(subject.map(&:id)).to eq(tokens.values_at(*expected_tokens).map(&:id))
        end
      end
    end

    describe 'delegates' do
      subject { described_class.new(default_params.merge(params), current_user) }

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
