# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::UsersController, :with_current_organization, feature_category: :user_management do
  let(:user) { create(:user) }

  let_it_be_with_reload(:admin) { create(:admin, organizations: [current_organization]) }

  before do
    sign_in(admin)
  end

  describe 'GET #index' do
    it 'retrieves all users' do
      get :index

      expect(assigns(:users)).to match_array([user, admin])
    end

    it 'filters by admins' do
      get :index, params: { filter: 'admins' }

      expect(assigns(:users)).to eq([admin])
    end

    context 'with search by partial email' do
      subject(:request) { get :index, params: { search_query: user.email[1...-1] } }

      context 'when Gitlab.com' do
        before do
          allow(Gitlab).to receive(:com?).and_return(true)
        end

        it 'does not search users by partial email' do
          request

          expect(assigns(:users)).to eq([])
        end
      end

      context 'when not Gitlab.com' do
        before do
          allow(Gitlab).to receive(:com?).and_return(false)
        end

        it 'searhes users by partial email' do
          request

          expect(assigns(:users)).to eq([user])
        end
      end
    end

    it 'eager loads authorized projects association' do
      get :index

      expect(assigns(:users).first.association(:authorized_projects)).to be_loaded
    end

    context 'pagination' do
      context 'when number of users is over the pagination limit' do
        before do
          stub_const('Admin::UsersController::PAGINATION_WITH_COUNT_LIMIT', 5)
          allow(Gitlab::Database::Count).to receive(:approximate_counts).with([User]).and_return({ User => 6 })
        end

        it 'marks the relation for pagination without counts' do
          get :index

          expect(assigns(:users)).to be_a(Kaminari::PaginatableWithoutCount)
        end
      end

      context 'when number of users is below the pagination limit' do
        it 'marks the relation for pagination with counts' do
          get :index

          expect(assigns(:users)).not_to be_a(Kaminari::PaginatableWithoutCount)
        end
      end
    end
  end

  describe 'GET :id' do
    it 'finds a user case-insensitively' do
      user = create(:user, username: 'CaseSensitive')

      get :show, params: { id: user.username.downcase }

      expect(response).to be_redirect
      expect(response.location).to end_with(user.username)
    end

    describe 'impersonation_error_text' do
      context 'when user can be impersonated' do
        it 'sets impersonation_error_text to nil' do
          get :show, params: { id: user.username.downcase }

          expect(assigns(:impersonation_error_text)).to eq(nil)
        end
      end

      context 'when impersonation is already in progress' do
        let(:admin2) { create(:admin) }

        before do
          post :impersonate, params: { id: admin2.username }
        end

        it 'sets impersonation_error_text' do
          get :show, params: { id: user.username.downcase }

          expect(assigns(:impersonation_error_text)).to eq(_("You are already impersonating another user"))
        end
      end

      context 'when user is blocked' do
        before do
          user.block
        end

        it 'sets impersonation_error_text' do
          get :show, params: { id: user.username.downcase }

          expect(assigns(:impersonation_error_text)).to eq(_("You cannot impersonate a blocked user"))
        end
      end

      context "when the user's password is expired" do
        before do
          user.update!(password_expires_at: 1.day.ago)
        end

        it 'sets impersonation_error_text' do
          get :show, params: { id: user.username.downcase }

          expect(assigns(:impersonation_error_text)).to eq(_("You cannot impersonate a user with an expired password"))
        end
      end

      context "when the user is internal" do
        before do
          user.update!(user_type: :migration_bot)
        end

        it 'sets impersonation_error_text' do
          get :show, params: { id: user.username.downcase }

          expect(assigns(:impersonation_error_text)).to eq(_("You cannot impersonate an internal user"))
        end
      end

      context "when the user is a project bot" do
        before do
          user.update!(user_type: :project_bot)
        end

        it 'sets impersonation_error_text' do
          get :show, params: { id: user.username.downcase }

          expect(assigns(:impersonation_error_text)).to eq(_("You cannot impersonate a user who cannot log in"))
        end
      end
    end

    describe 'can_impersonate' do
      context 'when user can be impersonated' do
        it 'sets can_impersonate to true' do
          get :show, params: { id: user.username.downcase }

          expect(assigns(:can_impersonate)).to eq(true)
        end
      end

      context 'when impersonation is already in progress' do
        let(:admin2) { create(:admin) }

        before do
          post :impersonate, params: { id: admin2.username }
        end

        it 'sets can_impersonate to false' do
          get :show, params: { id: user.username.downcase }

          expect(assigns(:can_impersonate)).to eq(false)
        end
      end

      context 'when user cannot log in' do
        before do
          user.update!(user_type: :project_bot)
        end

        it 'sets can_impersonate to false' do
          get :show, params: { id: user.username.downcase }

          expect(assigns(:can_impersonate)).to eq(false)
        end
      end
    end
  end

  describe 'DELETE #destroy', :sidekiq_might_not_need_inline do
    let(:project) { create(:project, namespace: user.namespace) }
    let!(:issue) { create(:issue, author: user) }

    before do
      project.add_developer(user)
    end

    it 'initiates user removal' do
      delete :destroy, params: { id: user.username }, format: :json

      expect(response).to have_gitlab_http_status(:ok)
      expect(Users::GhostUserMigration.where(user: user, initiator_user: admin, hard_delete: false)).to be_exists
    end

    it 'initiates user removal and passes hard delete option' do
      delete :destroy, params: { id: user.username, hard_delete: true }, format: :json

      expect(response).to have_gitlab_http_status(:ok)
      expect(Users::GhostUserMigration.where(user: user, initiator_user: admin, hard_delete: true)).to be_exists
    end

    context 'prerequisites for account deletion' do
      context 'solo-owned groups' do
        let(:group) { create(:group) }

        context 'if the user is the sole owner of at least one group' do
          before do
            create(:group_member, :owner, group: group, user: user)
          end

          context 'soft-delete' do
            it 'fails' do
              delete :destroy, params: { id: user.username }

              message = s_('AdminUsers|You must transfer ownership or delete the groups owned by this user before you can delete their account')

              expect(flash[:alert]).to eq(message)
              expect(response).to have_gitlab_http_status(:see_other)
              expect(response).to redirect_to admin_user_path(user)
              expect(Users::GhostUserMigration).not_to exist
            end
          end

          context 'hard-delete' do
            it 'succeeds' do
              delete :destroy, params: { id: user.username, hard_delete: true }

              expect(response).to redirect_to(admin_users_path)
              expect(flash[:notice]).to eq(_('The user is being deleted.'))
              expect(Users::GhostUserMigration.where(user: user, initiator_user: admin, hard_delete: true)).to be_exists
            end
          end
        end
      end
    end
  end

  describe 'DELETE #reject' do
    subject { put :reject, params: { id: user.username } }

    context 'when rejecting a pending user' do
      let(:user) { create(:user, :blocked_pending_approval) }

      it 'initiates user removal', :sidekiq_inline do
        subject

        expect(Users::GhostUserMigration.where(user: user, initiator_user: admin)).to be_exists
      end

      it 'displays the rejection message' do
        subject

        expect(response).to redirect_to(admin_user_path(user))
        expect(flash[:notice]).to eq("You've rejected #{user.name}")
      end

      it 'sends the user a rejection email' do
        expect_next_instance_of(NotificationService) do |notification|
          allow(notification).to receive(:user_admin_rejection).with(user.name, user.notification_email_or_default)
        end

        subject
      end
    end

    context 'when user is not pending' do
      let(:user) { create(:user, state: 'active') }

      it 'does not reject and delete the user' do
        subject

        expect(User.exists?(user.id)).to be_truthy
      end

      it 'displays the error' do
        subject

        expect(flash[:alert]).to eq('User does not have a pending request')
      end

      it 'does not email the user' do
        expect(NotificationService).not_to receive(:new)

        subject
      end
    end
  end

  describe 'PUT #approve' do
    let(:user) { create(:user, :blocked_pending_approval) }

    subject { put :approve, params: { id: user.username } }

    context 'when successful' do
      it 'activates the user' do
        subject

        user.reload

        expect(user).to be_active
        expect(flash[:notice]).to eq('Successfully approved')
      end

      it 'emails the user on approval' do
        expect(DeviseMailer).to receive(:user_admin_approval).with(user).and_call_original
        expect { subject }.to have_enqueued_mail(DeviseMailer, :user_admin_approval)
      end
    end

    context 'when unsuccessful' do
      let(:user) { create(:user, :blocked) }

      it 'displays the error' do
        subject

        expect(flash[:alert]).to eq('The user you are trying to approve is not pending approval')
      end

      it 'does not activate the user' do
        subject

        user.reload
        expect(user).not_to be_active
      end

      it 'does not email the pending user' do
        expect { subject }.not_to have_enqueued_mail(DeviseMailer, :user_admin_approval)
      end
    end
  end

  describe 'PUT #activate' do
    shared_examples 'a request that activates the user' do
      it 'activates the user' do
        put :activate, params: { id: user.username }
        user.reload
        expect(user.active?).to be_truthy
        expect(flash[:notice]).to eq('Successfully activated')
      end
    end

    context 'for a deactivated user' do
      before do
        user.deactivate
      end

      it_behaves_like 'a request that activates the user'
    end

    context 'for an active user' do
      it_behaves_like 'a request that activates the user'
    end

    context 'for a blocked user' do
      before do
        user.block
      end

      it 'does not activate the user' do
        put :activate, params: { id: user.username }
        user.reload
        expect(user.active?).to be_falsey
        expect(flash[:alert]).to eq('Error occurred. A blocked user must be unblocked to be activated')
      end
    end
  end

  describe 'PUT #deactivate' do
    shared_examples 'a request that deactivates the user' do
      it 'deactivates the user' do
        put :deactivate, params: { id: user.username }
        user.reload
        expect(user.deactivated?).to be_truthy
        expect(flash[:notice]).to eq('Successfully deactivated')
      end
    end

    context 'for an active user' do
      let(:activity) { {} }
      let(:user) { create(:user, **activity) }

      context 'with no recent activity' do
        let(:activity) { { last_activity_on: Gitlab::CurrentSettings.deactivate_dormant_users_period.next.days.ago } }

        it_behaves_like 'a request that deactivates the user'
      end

      context 'with recent activity' do
        let(:activity) { { last_activity_on: Gitlab::CurrentSettings.deactivate_dormant_users_period.pred.days.ago } }

        it 'does not deactivate the user' do
          put :deactivate, params: { id: user.username }
          user.reload
          expect(user.deactivated?).to be_falsey
          expect(flash[:alert]).to eq("The user you are trying to deactivate has been active in the past #{Gitlab::CurrentSettings.deactivate_dormant_users_period} days and cannot be deactivated")
        end
      end
    end

    context 'for a deactivated user' do
      before do
        user.deactivate
      end

      it_behaves_like 'a request that deactivates the user'
    end

    context 'for a blocked user' do
      before do
        user.block
      end

      it 'does not deactivate the user' do
        put :deactivate, params: { id: user.username }
        user.reload
        expect(user.deactivated?).to be_falsey
        expect(flash[:alert]).to eq('Error occurred. A blocked user cannot be deactivated')
      end
    end

    context 'for an internal user' do
      it 'does not deactivate the user' do
        internal_user = Users::Internal.alert_bot

        put :deactivate, params: { id: internal_user.username }

        expect(internal_user.reload.deactivated?).to be_falsey
        expect(flash[:alert]).to eq('Internal users cannot be deactivated')
      end
    end
  end

  describe 'PUT block/:id' do
    it 'blocks user' do
      put :block, params: { id: user.username }
      user.reload
      expect(user.blocked?).to be_truthy
      expect(flash[:notice]).to eq _('Successfully blocked')
    end
  end

  describe 'PUT unblock/:id' do
    context 'ldap blocked users' do
      let(:user) { create(:omniauth_user, provider: 'ldapmain') }

      before do
        user.ldap_block
      end

      it 'does not unblock user' do
        put :unblock, params: { id: user.username }
        user.reload
        expect(user.blocked?).to be_truthy
        expect(flash[:alert]).to eq _('This user cannot be unlocked manually from GitLab')
      end
    end

    context 'manually blocked users' do
      before do
        user.block
      end

      it 'unblocks user' do
        put :unblock, params: { id: user.username }
        user.reload
        expect(user.blocked?).to be_falsey
        expect(flash[:notice]).to eq _('Successfully unblocked')
      end
    end
  end

  describe 'PUT ban/:id', :aggregate_failures do
    it 'bans user' do
      put :ban, params: { id: user.username }

      expect(user.reload.banned?).to be_truthy
      expect(flash[:notice]).to eq _('Successfully banned')
    end

    context 'when unsuccessful' do
      let(:user) { create(:user, :blocked) }

      it 'does not ban user' do
        put :ban, params: { id: user.username }

        user.reload
        expect(user.banned?).to be_falsey
        expect(flash[:alert]).to eq _('Error occurred. User was not banned')
      end
    end
  end

  describe 'PUT unban/:id', :aggregate_failures do
    let(:banned_user) { create(:user, :banned) }

    it 'unbans user' do
      put :unban, params: { id: banned_user.username }

      expect(banned_user.reload.banned?).to be_falsey
      expect(flash[:notice]).to eq _('Successfully unbanned')
    end
  end

  describe 'PUT unlock/:id' do
    before do
      request.env["HTTP_REFERER"] = "/"
      user.lock_access!
    end

    it 'unlocks user' do
      put :unlock, params: { id: user.username }
      user.reload
      expect(user.access_locked?).to be_falsey
      expect(flash[:notice]).to eq _('Successfully unlocked')
    end
  end

  describe 'PUT confirm/:id' do
    shared_examples_for 'confirms the user' do
      it 'confirms the user' do
        put :confirm, params: { id: user.username }
        user.reload
        expect(user.confirmed?).to be_truthy
      end
    end

    let(:expired_confirmation_sent_at) { Date.today - User.confirm_within - 7.days }
    let(:extant_confirmation_sent_at) { Date.today }

    let(:user) do
      create(:user, :unconfirmed).tap do |user|
        user.update!(confirmation_sent_at: confirmation_sent_at)
      end
    end

    before do
      request.env["HTTP_REFERER"] = "/"
    end

    context 'when the confirmation period has expired' do
      let(:confirmation_sent_at) { expired_confirmation_sent_at }

      it_behaves_like 'confirms the user'
    end

    context 'when the confirmation period has not expired' do
      let(:confirmation_sent_at) { extant_confirmation_sent_at }

      it_behaves_like 'confirms the user'
    end
  end

  describe 'PATCH disable_two_factor' do
    subject { patch :disable_two_factor, params: { id: user.to_param } }

    context 'for a user that has 2FA enabled' do
      let(:user) { create(:user, :two_factor) }

      it 'disables 2FA for the user' do
        subject

        expect(user.reload.two_factor_enabled?).to eq(false)
      end

      it 'redirects back' do
        subject

        expect(response).to redirect_to(admin_user_path(user))
      end

      it 'displays a notice on success' do
        subject

        expect(flash[:notice])
          .to eq _('Two-factor authentication has been disabled for this user')
      end
    end

    context 'for a user that does not have 2FA enabled' do
      it 'redirects back' do
        subject

        expect(response).to redirect_to(admin_user_path(user))
      end

      it 'displays an alert on failure' do
        subject

        expect(flash[:alert])
          .to eq _('Two-factor authentication is not enabled for this user')
      end
    end
  end

  describe 'POST #create' do
    let_it_be(:user_params) { attributes_for(:user) }

    it 'creates the user' do
      expect { post :create, params: { user: user_params } }.to change { User.count }.by(1)
    end

    it 'shows only one error message for an invalid email' do
      post :create, params: { user: user_params.merge(email: 'bogus') }

      errors = assigns[:user].errors
      expect(errors).to contain_exactly(errors.full_message(:email, I18n.t('errors.messages.invalid')))
    end

    it 'creates user with namespace in the Current.organization', :aggregate_failures do
      post :create, params: { user: user_params }

      created_user = User.find_by(email: user_params[:email])

      expect(created_user.namespace.organization).to eq(Current.organization)
      expect(created_user.organizations).to contain_exactly(Current.organization)
    end

    [%w[admin owner], %w[user default]].each do |user_access_level, organization_access_level|
      context "when access level is #{user_access_level}" do
        it "creates organization user with #{organization_access_level} access" do
          post :create, params: { user: user_params.merge(access_level: user_access_level) }

          access_level = Organizations::OrganizationUser
           .joins(:user)
           .where(users: { email: user_params[:email] })
           .where(organization_id: Current.organization.id)
           .pick(:access_level)

          expect(access_level).to eq(organization_access_level)
        end
      end
    end

    context 'when organization params is provided' do
      let(:organization) { create(:organization) }
      let(:organization_params) { { organization_id: organization.id, organization_access_level: 'owner' } }

      it 'creates user record and namespace in the organization', :aggregate_failures do
        post :create, params: { user: user_params.merge(organization_params) }

        created_user = User.find_by(email: user_params[:email])

        expect(created_user.namespace.organization).to eq(organization)
        expect(created_user.organizations).to include(organization)
      end

      context 'when organization param is invalid' do
        subject(:request) { post :create, params: { user: user_params.merge({ organization_id: non_existing_record_id }) } }

        it 'does not create user' do
          expect { request }.not_to change { User.count }
        end

        it 'returns organization error' do
          request

          errors = assigns[:user].errors
          expect(errors).to contain_exactly(_("Namespace organization can't be blank"), _('Organization users organization must exist'))
        end
      end
    end

    context 'admin notes' do
      it 'creates the user with note' do
        note = '2020-05-12 | Note | DCMA | Link'
        params = { user: user_params.merge(note: note) }

        expect { post :create, params: params }.to change { User.count }.by(1)

        new_user = User.last
        expect(new_user.note).to eq(note)
      end
    end
  end

  describe 'POST update' do
    let_it_be(:organization) { create(:organization, organization_users: create_list(:organization_owner, 3)) }
    let_it_be(:organization_user) { organization.organization_users.first }
    let_it_be(:current_user) { organization_user.user }

    Organizations::OrganizationUser.access_levels.each_key do |organization_access_level|
      context "when organization_access_level param is #{organization_access_level}" do
        it "updates organization user access level to #{organization_access_level}" do
          post :update, params: {
            id: current_user.to_param,
            user: {
              organization_users_attributes: [{
                id: organization_user.id,
                organization_id: organization_user.organization_id,
                access_level: organization_access_level
              }]
            }
          }

          expect(organization_user.reload.access_level).to eq(organization_access_level)
        end
      end
    end

    context 'when target user does not belong to the organization' do
      let_it_be(:new_user) { create(:user) }

      it 'adds user to the organization' do
        post :update, params: {
          id: new_user.to_param,
          user: { organization_users_attributes: [{ organization_id: organization.id }] }
        }

        expect(organization.user?(new_user)).to eq(true)
      end
    end

    context 'when organization parameters is invalid' do
      let_it_be(:params) do
        {
          id: current_user.to_param,
          user: { organization_users_attributes: [{ organization_id: non_existing_record_id }] }
        }
      end

      it 'returns error message' do
        post :update, params: params

        expect(assigns[:user].errors).to contain_exactly(_('Organization users organization must exist'))
      end

      context 'when format is json' do
        it 'returns json with error message', :aggregate_failures do
          post :update, params: params, format: :json

          expect(response).to have_gitlab_http_status(:internal_server_error)
          expect(json_response).to contain_exactly(_('Organization users organization must exist'))
        end
      end
    end

    context 'when organization_users param count exceeds limit' do
      before do
        stub_const("#{described_class}::ORGANIZATION_USERS_LIMIT", 1)
      end

      let_it_be(:organization_users_attributes) do
        create_list(:organization_user, Users::UpdateService::ORGANIZATION_USERS_LIMIT + 1, user: current_user)
          .map { |o| o.slice(:id) }
      end

      let_it_be(:error_message) do
        format(
          _('Cannot update more than %{limit} organization data at once'),
          limit: Users::UpdateService::ORGANIZATION_USERS_LIMIT
        )
      end

      let_it_be(:params) do
        { id: current_user.to_param, user: { organization_users_attributes: organization_users_attributes } }
      end

      it 'returns error message' do
        post :update, params: params

        expect(assigns[:user].errors).to contain_exactly(error_message)
      end

      context 'when format is json' do
        it 'returns json with error message', :aggregate_failures do
          post :update, params: params, format: :json

          expect(response).to have_gitlab_http_status(:internal_server_error)
          expect(json_response).to contain_exactly(error_message)
        end
      end
    end

    context 'when the password has changed' do
      def update_password(user, password = User.random_password, password_confirmation = password, format = :html)
        params = {
          id: user.to_param,
          user: {
            password: password,
            password_confirmation: password_confirmation
          }
        }

        post :update, params: params, format: format
      end

      context 'when admin changes their own password' do
        context 'when password is valid' do
          it 'updates the password' do
            expect { update_password(admin) }
              .to change { admin.reload.encrypted_password }
          end

          it 'does not set the new password to expire immediately' do
            expect { update_password(admin) }
              .not_to change { admin.reload.password_expired? }
          end

          it 'does not enqueue the `admin changed your password` email' do
            expect { update_password(admin) }
              .not_to have_enqueued_mail(DeviseMailer, :password_change_by_admin)
          end

          it 'enqueues the `password changed` email' do
            expect { update_password(admin) }
              .to have_enqueued_mail(DeviseMailer, :password_change)
          end
        end
      end

      context 'when admin changes the password of another user' do
        context 'when the new password is valid' do
          it 'redirects to the user' do
            update_password(user)

            expect(response).to redirect_to(admin_user_path(user))
          end

          it 'updates the password' do
            expect { update_password(user) }
              .to change { user.reload.encrypted_password }
          end

          it 'sets the new password to expire immediately' do
            expect { update_password(user) }
              .to change { user.reload.password_expired? }.from(false).to(true)
          end

          it 'enqueues the `admin changed your password` email' do
            expect { update_password(user) }
              .to have_enqueued_mail(DeviseMailer, :password_change_by_admin)
          end

          it 'does not enqueue the `password changed` email' do
            expect { update_password(user) }
              .not_to have_enqueued_mail(DeviseMailer, :password_change)
          end
        end
      end

      context 'when the new password is invalid' do
        let(:password) { 'invalid' }

        it 'shows the edit page again' do
          update_password(user, password)

          expect(response).to render_template(:edit)
        end

        it 'returns the error message' do
          update_password(user, password)

          expect(assigns[:user].errors).to contain_exactly(a_string_matching(/too short/))
        end

        it 'does not update the password' do
          expect { update_password(user, password) }
            .not_to change { user.reload.encrypted_password }
        end
      end

      context 'when the new password does not match the password confirmation' do
        let(:password) { User.random_password }
        let(:password_confirmation) { User.random_password }

        it 'shows the edit page again' do
          update_password(user, password, password_confirmation)

          expect(response).to render_template(:edit)
        end

        it 'returns the error message' do
          update_password(user, password, password_confirmation)

          expect(assigns[:user].errors).to contain_exactly(a_string_matching(/doesn't match/))
        end

        it 'does not update the password' do
          expect { update_password(user, password, password_confirmation) }
            .not_to change { user.reload.encrypted_password }
        end
      end

      context 'when the update fails' do
        let(:password) { User.random_password }

        before do
          expect_next_instance_of(Users::UpdateService) do |service|
            allow(service).to receive(:execute).and_return({ message: 'failed', status: :error })
          end
        end

        it 'returns a 500 error' do
          expect { update_password(admin, password, password, :json) }
            .not_to change { admin.reload.password_expired? }

          expect(response).to have_gitlab_http_status(:error)
        end
      end
    end

    context 'admin notes' do
      it 'updates the note for the user' do
        note = '2020-05-12 | Note | DCMA | Link'
        params = {
          id: user.to_param,
          user: {
            note: note
          }
        }

        expect { post :update, params: params }.to change { user.reload.note }.to(note)
      end
    end

    context 'when updating credit card validation for user account' do
      let(:params) do
        {
          id: user.to_param,
          user: user_params
        }
      end

      shared_examples 'no credit card validation param' do
        let(:user_params) { { name: 'foo' } }

        it 'does not change credit card validation' do
          expect { post :update, params: params }.not_to change(Users::CreditCardValidation, :count)
        end
      end

      context 'when user has a credit card validation' do
        before do
          user.create_credit_card_validation!(credit_card_validated_at: Time.zone.now)
        end

        context 'with unchecked credit card validation' do
          let(:user_params) do
            { credit_card_validation_attributes: { credit_card_validated_at: '0' } }
          end

          it 'deletes credit_card_validation' do
            expect { post :update, params: params }.to change { Users::CreditCardValidation.count }.by(-1)
          end
        end

        context 'with checked credit card validation' do
          let(:user_params) do
            { credit_card_validation_attributes: { credit_card_validated_at: '1' } }
          end

          it 'does not change credit_card_validated_at' do
            expect { post :update, params: params }.not_to change { user.credit_card_validated_at }
          end
        end

        it_behaves_like 'no credit card validation param'
      end

      context 'when user does not have a credit card validation' do
        context 'with checked credit card validation' do
          let(:user_params) do
            { credit_card_validation_attributes: { credit_card_validated_at: '1' } }
          end

          it 'creates new credit card validation' do
            expect { post :update, params: params }.to change { Users::CreditCardValidation.count }.by 1
          end
        end

        context 'with unchecked credit card validation' do
          let(:user_params) do
            { credit_card_validation_attributes: { credit_card_validated_at: '0' } }
          end

          it 'does not blow up' do
            expect { post :update, params: params }.not_to change(Users::CreditCardValidation, :count)
          end
        end

        it_behaves_like 'no credit card validation param'
      end

      context 'invalid parameters' do
        let(:user_params) do
          { credit_card_validation_attributes: { credit_card_validated_at: Time.current.iso8601 } }
        end

        it_behaves_like 'no credit card validation param'
      end

      context 'with non permitted params' do
        let(:user_params) do
          { credit_card_validation_attributes: { _destroy: true } }
        end

        before do
          user.create_credit_card_validation!(credit_card_validated_at: Time.zone.now)
        end

        it_behaves_like 'no credit card validation param'
      end
    end
  end

  describe "DELETE #remove_email" do
    it 'deletes the email' do
      email = create(:email, user: user)

      delete :remove_email, params: { id: user.username, email_id: email.id }

      expect(user.reload.emails).not_to include(email)
      expect(flash[:notice]).to eq('Successfully removed email.')
    end
  end

  describe "POST impersonate" do
    context "when the user is blocked" do
      before do
        user.block!
      end

      it "shows a notice" do
        post :impersonate, params: { id: user.username }

        expect(flash[:alert]).to eq(_('You cannot impersonate a blocked user'))
      end

      it "doesn't sign us in as the user" do
        post :impersonate, params: { id: user.username }

        expect(warden.user).to eq(admin)
      end
    end

    context "when the user is not blocked" do
      it "stores the impersonator in the session" do
        post :impersonate, params: { id: user.username }

        expect(session[:impersonator_id]).to eq(admin.id)
      end

      it "signs us in as the user" do
        post :impersonate, params: { id: user.username }

        expect(warden.user).to eq(user)
      end

      it 'logs the beginning of the impersonation event' do
        expect(Gitlab::AppLogger).to receive(:info).with("User #{admin.username} has started impersonating #{user.username}").and_call_original

        post :impersonate, params: { id: user.username }
      end

      it "redirects to root" do
        post :impersonate, params: { id: user.username }

        expect(response).to redirect_to(root_path)
      end

      it "shows a notice" do
        post :impersonate, params: { id: user.username }

        expect(flash[:notice]).to eq("You are now impersonating #{user.username}")
      end

      it 'clears token session keys' do
        session[:github_access_token] = SecureRandom.hex(8)

        post :impersonate, params: { id: user.username }

        expect(session[:github_access_token]).to be_nil
      end

      context "when the user's password is expired" do
        before do
          user.update!(password_expires_at: 1.day.ago)
        end

        it "shows a notice" do
          post :impersonate, params: { id: user.username }

          expect(flash[:alert]).to eq(_('You cannot impersonate a user with an expired password'))
        end

        it "doesn't sign us in as the user" do
          post :impersonate, params: { id: user.username }

          expect(warden.user).to eq(admin)
        end
      end

      context "when the user is internal" do
        before do
          user.update!(user_type: :migration_bot)
        end

        it "shows a notice" do
          post :impersonate, params: { id: user.username }

          expect(flash[:alert]).to eq(_("You cannot impersonate an internal user"))
        end

        it "doesn't sign us in as the user" do
          post :impersonate, params: { id: user.username }

          expect(warden.user).to eq(admin)
        end
      end

      context "when the user is a project bot" do
        before do
          user.update!(user_type: :project_bot)
        end

        it "shows a notice" do
          post :impersonate, params: { id: user.username }

          expect(flash[:alert]).to eq(_("You cannot impersonate a user who cannot log in"))
        end

        it "doesn't sign us in as the user" do
          post :impersonate, params: { id: user.username }

          expect(warden.user).to eq(admin)
        end
      end
    end

    context "when impersonation is disabled" do
      before do
        stub_config_setting(impersonation_enabled: false)
      end

      it "shows error page" do
        post :impersonate, params: { id: user.username }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when impersonating an admin and attempting to impersonate again' do
      let(:admin2) { create(:admin) }

      before do
        post :impersonate, params: { id: admin2.username }
      end

      it 'does not allow double impersonation', :aggregate_failures do
        post :impersonate, params: { id: user.username }

        expect(flash[:alert]).to eq(_('You are already impersonating another user'))
        expect(warden.user).to eq(admin2)
      end
    end
  end
end
