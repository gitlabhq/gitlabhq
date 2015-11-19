require 'spec_helper'

describe Admin::UsersController do
  let(:admin)    { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'DELETE #user with projects' do
    let(:user) { create(:user) }
    let(:project) { create(:project, namespace: user.namespace) }

    before do
      project.team << [user, :developer]
    end

    it 'deletes user' do
      delete :destroy, id: user.username, format: :json
      expect(response.status).to eq(200)
      expect { User.find(user.id) }.to raise_exception(ActiveRecord::RecordNotFound)
    end
  end

  describe 'PUT block/:id' do
    let(:user) { create(:user) }

    it 'blocks user' do
      put :block, id: user.username
      user.reload
      expect(user.blocked?).to be_truthy
      expect(flash[:notice]).to eq 'Successfully blocked'
    end
  end

  describe 'PUT unblock/:id' do
    let(:user) { create(:user) }

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

  describe 'PUT unlock/:id' do
    let(:user) { create(:user) }

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
    let(:user) { create(:user) }

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

      expect(flash[:notice]).
        to eq 'Two-factor Authentication has been disabled for this user'
    end

    def go
      patch :disable_two_factor, id: user.to_param
    end
  end
end
