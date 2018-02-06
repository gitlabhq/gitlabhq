require 'spec_helper'

describe Admin::UsersController do
  let(:user) { create(:user) }
  set(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'DELETE #user with projects' do
    let(:project) { create(:project, namespace: user.namespace) }
    let!(:issue) { create(:issue, author: user) }

    before do
      project.add_developer(user)
    end

    it 'deletes user and ghosts their contributions' do
      delete :destroy, id: user.username, format: :json

      expect(response).to have_gitlab_http_status(200)
      expect(User.exists?(user.id)).to be_falsy
      expect(issue.reload.author).to be_ghost
    end

    it 'deletes the user and their contributions when hard delete is specified' do
      delete :destroy, id: user.username, hard_delete: true, format: :json

      expect(response).to have_gitlab_http_status(200)
      expect(User.exists?(user.id)).to be_falsy
      expect(Issue.exists?(issue.id)).to be_falsy
    end
  end

  describe 'PUT block/:id' do
    it 'blocks user' do
      put :block, id: user.username
      user.reload
      expect(user.blocked?).to be_truthy
      expect(flash[:notice]).to eq 'Successfully blocked'
    end
  end

  describe 'PUT unblock/:id' do
    context 'ldap blocked users' do
      let(:user) { create(:omniauth_user, provider: 'ldapmain') }

      before do
        user.ldap_block
      end

      it 'does not unblock user' do
        put :unblock, id: user.username
        user.reload
        expect(user.blocked?).to be_truthy
        expect(flash[:alert]).to eq 'This user cannot be unlocked manually from GitLab'
      end
    end

    context 'manually blocked users' do
      before do
        user.block
      end

      it 'unblocks user' do
        put :unblock, id: user.username
        user.reload
        expect(user.blocked?).to be_falsey
        expect(flash[:notice]).to eq 'Successfully unblocked'
      end
    end
  end

  describe 'PUT unlock/:id' do
    before do
      request.env["HTTP_REFERER"] = "/"
      user.lock_access!
    end

    it 'unlocks user' do
      put :unlock, id: user.username
      user.reload
      expect(user.access_locked?).to be_falsey
    end
  end

  describe 'PUT confirm/:id' do
    let(:user) { create(:user, confirmed_at: nil) }

    before do
      request.env["HTTP_REFERER"] = "/"
    end

    it 'confirms user' do
      put :confirm, id: user.username
      user.reload
      expect(user.confirmed?).to be_truthy
    end
  end

  describe 'PATCH disable_two_factor' do
    it 'disables 2FA for the user' do
      expect(user).to receive(:disable_two_factor!)
      allow(subject).to receive(:user).and_return(user)

      go
    end

    it 'redirects back' do
      go

      expect(response).to redirect_to(admin_user_path(user))
    end

    it 'displays an alert' do
      go

      expect(flash[:notice])
        .to eq 'Two-factor Authentication has been disabled for this user'
    end

    def go
      patch :disable_two_factor, id: user.to_param
    end
  end

  describe 'POST create' do
    it 'creates the user' do
      expect { post :create, user: attributes_for(:user) }.to change { User.count }.by(1)
    end

    it 'shows only one error message for an invalid email' do
      post :create, user: attributes_for(:user, email: 'bogus')
      expect(assigns[:user].errors).to contain_exactly("Email is invalid")
    end
  end

  describe 'POST update' do
    context 'when the password has changed' do
      def update_password(user, password, password_confirmation = nil)
        params = {
          id: user.to_param,
          user: {
            password: password,
            password_confirmation: password_confirmation || password
          }
        }

        post :update, params
      end

      context 'when the admin changes his own password' do
        it 'updates the password' do
          expect { update_password(admin, 'AValidPassword1') }
            .to change { admin.reload.encrypted_password }
        end

        it 'does not set the new password to expire immediately' do
          expect { update_password(admin, 'AValidPassword1') }
            .not_to change { admin.reload.password_expires_at }
        end
      end

      context 'when the new password is valid' do
        it 'redirects to the user' do
          update_password(user, 'AValidPassword1')

          expect(response).to redirect_to(admin_user_path(user))
        end

        it 'updates the password' do
          expect { update_password(user, 'AValidPassword1') }
            .to change { user.reload.encrypted_password }
        end

        it 'sets the new password to expire immediately' do
          expect { update_password(user, 'AValidPassword1') }
            .to change { user.reload.password_expires_at }.to be_within(2.seconds).of(Time.now)
        end
      end

      context 'when the new password is invalid' do
        it 'shows the edit page again' do
          update_password(user, 'invalid')

          expect(response).to render_template(:edit)
        end

        it 'returns the error message' do
          update_password(user, 'invalid')

          expect(assigns[:user].errors).to contain_exactly(a_string_matching(/too short/))
        end

        it 'does not update the password' do
          expect { update_password(user, 'invalid') }
            .not_to change { user.reload.encrypted_password }
        end
      end

      context 'when the new password does not match the password confirmation' do
        it 'shows the edit page again' do
          update_password(user, 'AValidPassword1', 'AValidPassword2')

          expect(response).to render_template(:edit)
        end

        it 'returns the error message' do
          update_password(user, 'AValidPassword1', 'AValidPassword2')

          expect(assigns[:user].errors).to contain_exactly(a_string_matching(/doesn't match/))
        end

        it 'does not update the password' do
          expect { update_password(user, 'AValidPassword1', 'AValidPassword2') }
            .not_to change { user.reload.encrypted_password }
        end
      end
    end
  end

  describe "POST impersonate" do
    context "when the user is blocked" do
      before do
        user.block!
      end

      it "shows a notice" do
        post :impersonate, id: user.username

        expect(flash[:alert]).to eq("You cannot impersonate a blocked user")
      end

      it "doesn't sign us in as the user" do
        post :impersonate, id: user.username

        expect(warden.user).to eq(admin)
      end
    end

    context "when the user is not blocked" do
      it "stores the impersonator in the session" do
        post :impersonate, id: user.username

        expect(session[:impersonator_id]).to eq(admin.id)
      end

      it "signs us in as the user" do
        post :impersonate, id: user.username

        expect(warden.user).to eq(user)
      end

      it "redirects to root" do
        post :impersonate, id: user.username

        expect(response).to redirect_to(root_path)
      end

      it "shows a notice" do
        post :impersonate, id: user.username

        expect(flash[:alert]).to eq("You are now impersonating #{user.username}")
      end
    end
  end
end
