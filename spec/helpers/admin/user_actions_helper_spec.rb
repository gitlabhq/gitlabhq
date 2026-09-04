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
      # `freeze: false` is required in this spec: one or more `let_it_be` subjects
      # cannot be frozen by default (deep_freeze traversal failure, a non-AR
      # subject, or an in-memory mutation that survives reload/refind). Do not
      # drop these opt-outs or convert them to `let_it_be_with_reload`/`refind`
      # (see gitlab-org/gitlab#602925).
      let_it_be(:user, freeze: false) { create(:user) }

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
      let_it_be(:user, freeze: false) { create(:user, :admin) }

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
      let_it_be(:user, freeze: false) { create(:omniauth_user, :ldap_blocked) }

      it { is_expected.to contain_exactly("edit", "ldap", "delete", "delete_with_contributions") }
    end

    context 'the user is blocked pending approval' do
      let_it_be(:user, freeze: false) { create(:user, :blocked_pending_approval) }

      it { is_expected.to contain_exactly("edit", "approve", "reject") }
    end

    context 'the user is blocked' do
      let_it_be(:user, freeze: false) { create(:user, :blocked) }

      it { is_expected.to contain_exactly("edit", "unblock", "delete", "delete_with_contributions") }
    end

    context 'the user is deactivated' do
      let_it_be(:user, freeze: false) { create(:user, :deactivated) }

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
      let_it_be(:user, freeze: false) { create(:user) }

      before do
        user.lock_access!
      end

      it do
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
      end
    end

    context 'the user is banned' do
      let_it_be(:user, freeze: false) { create(:user, :banned) }

      it { is_expected.to contain_exactly("edit", "unban", "delete", "delete_with_contributions") }
    end

    context 'the user is trusted' do
      let_it_be(:user, freeze: false) { create(:user, :trusted) }

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
      let_it_be(:user, freeze: false) { create(:user) }

      before_all do
        group.add_owner(user)
      end

      it { is_expected.to contain_exactly("edit", "block", "ban", "deactivate", "delete_with_contributions", "trust") }
    end

    context 'the user is a bot' do
      let_it_be(:user, freeze: false) { create(:user, :bot) }

      it { is_expected.to match_array([]) }
    end

    context 'for the remove_from_organization action' do
      let_it_be(:organization) { create(:organization) }
      let_it_be(:user, freeze: false) { create(:user, organizations: [organization]) }

      context 'when on the organization admin page' do
        before do
          allow(helper).to receive(:options).and_return(authorization_context: organization)
        end

        context 'when the current user can remove the organization user' do
          before do
            allow(current_user).to receive(:can?).and_call_original
            allow(current_user).to receive(:can?)
              .with(:delete_organization_user, an_instance_of(Organizations::OrganizationUser))
              .and_return(true)
          end

          it { is_expected.to include('remove_from_organization') }
        end

        context 'when the current user cannot remove the organization user' do
          before do
            allow(current_user).to receive(:can?).and_call_original
            allow(current_user).to receive(:can?)
              .with(:delete_organization_user, an_instance_of(Organizations::OrganizationUser))
              .and_return(false)
          end

          it { is_expected.not_to include('remove_from_organization') }
        end

        context 'when the user does not belong to the organization' do
          let_it_be(:user, freeze: false) { create(:user) }

          it { is_expected.not_to include('remove_from_organization') }
        end

        context 'when driven by the real :delete_organization_user ability' do
          before do
            allow(helper).to receive(:can?).and_call_original
            allow(helper).to receive(:can?).with(current_user, :admin_all_resources).and_return(true)
          end

          context 'when the current user is an organization owner' do
            let_it_be(:current_user) do
              create(:organization_owner, organization: organization).user
            end

            it { is_expected.to include('remove_from_organization') }
          end

          context 'when the current user is not an organization owner' do
            let_it_be(:current_user) { create(:user) }

            it { is_expected.not_to include('remove_from_organization') }
          end
        end
      end

      context 'when not on the organization admin page' do
        before do
          allow(helper).to receive(:options).and_return(authorization_context: nil)
        end

        it { is_expected.not_to include('remove_from_organization') }
      end
    end
  end

  describe '#organization_user_gid', :enable_admin_mode do
    let_it_be(:organization) { create(:organization) }
    let_it_be(:user) { create(:user, organizations: [organization]) }

    subject(:gid) { helper.organization_user_gid(user) }

    context 'when on the organization admin page' do
      before do
        allow(helper).to receive(:options).and_return(authorization_context: organization)
      end

      it 'returns the organization user global ID' do
        organization_user = organization.organization_users.by_user(user).first

        expect(gid).to eq(organization_user.to_global_id.to_s)
      end

      context 'when the user does not belong to the organization' do
        let_it_be(:user) { create(:user) }

        it { is_expected.to be_nil }
      end
    end

    context 'when not on the organization admin page' do
      before do
        allow(helper).to receive(:options).and_return(authorization_context: nil)
      end

      it { is_expected.to be_nil }
    end
  end
end
