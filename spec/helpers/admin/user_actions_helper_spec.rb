# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admin::UserActionsHelper, feature_category: :user_management do
  describe '#admin_actions', :enable_admin_mode do
    let_it_be(:current_user) { build(:user, :admin) }

    subject { helper.admin_actions(user) }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
    end

    context 'the user is a bot' do
      let_it_be(:user) { build(:user, :bot) }

      it { is_expected.to be_empty }
    end

    context 'the current user and user are the same' do
      let_it_be(:user) { current_user }

      it { is_expected.to contain_exactly("edit") }
    end

    context 'the user is a standard user' do
      let_it_be(:user) { create(:user) }

      it do
        is_expected.to contain_exactly(
          "edit",
          "block",
          "ban",
          "deactivate",
          "delete",
          "delete_with_contributions",
          "trust"
        )
      end
    end

    context 'the user is an admin user' do
      let_it_be(:user) { create(:user, :admin) }

      it do
        is_expected.to contain_exactly(
          "edit",
          "block",
          "ban",
          "deactivate",
          "delete",
          "delete_with_contributions",
          "trust"
        )
      end
    end

    context 'the user is blocked by LDAP' do
      let_it_be(:user) { create(:omniauth_user, :ldap_blocked) }

      it { is_expected.to contain_exactly("edit", "ldap", "delete", "delete_with_contributions") }
    end

    context 'the user is blocked pending approval' do
      let_it_be(:user) { create(:user, :blocked_pending_approval) }

      it { is_expected.to contain_exactly("edit", "approve", "reject") }
    end

    context 'the user is blocked' do
      let_it_be(:user) { create(:user, :blocked) }

      it { is_expected.to contain_exactly("edit", "unblock", "delete", "delete_with_contributions") }
    end

    context 'the user is deactivated' do
      let_it_be(:user) { create(:user, :deactivated) }

      it do
        is_expected.to contain_exactly(
          "edit",
          "block",
          "ban",
          "activate",
          "delete",
          "delete_with_contributions"
        )
      end
    end

    context 'the user is locked' do
      let_it_be(:user) { create(:user) }

      before do
        user.lock_access!
      end

      it {
        is_expected.to contain_exactly(
          "edit",
          "block",
          "ban",
          "deactivate",
          "unlock",
          "delete",
          "delete_with_contributions",
          "trust"
        )
      }
    end

    context 'the user is banned' do
      let_it_be(:user) { create(:user, :banned) }

      it { is_expected.to contain_exactly("edit", "unban", "delete", "delete_with_contributions") }
    end

    context 'the user is trusted' do
      let_it_be(:user) { create(:user, :trusted) }

      it do
        is_expected.to contain_exactly("edit",
          "block",
          "deactivate",
          "ban",
          "delete",
          "delete_with_contributions",
          "untrust"
        )
      end
    end

    context 'the current_user does not have permission to delete the user' do
      let_it_be(:user) { build(:user) }

      before do
        allow(helper).to receive(:can?).and_call_original
        allow(helper).to receive(:can?).with(current_user, :destroy_user, user).and_return(false)
      end

      it { is_expected.to contain_exactly("edit", "block", "ban", "deactivate", "trust") }
    end

    context 'the user is a sole owner of a group' do
      let_it_be(:group) { create(:group) }
      let_it_be(:user) { create(:user) }

      before do
        group.add_owner(user)
      end

      it { is_expected.to contain_exactly("edit", "block", "ban", "deactivate", "delete_with_contributions", "trust") }
    end

    context 'the user is a bot' do
      let_it_be(:user) { create(:user, :bot) }

      it { is_expected.to match_array([]) }
    end
  end
end
