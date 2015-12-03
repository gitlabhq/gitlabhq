require 'spec_helper'

describe Admin::ImpersonationController do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'CREATE #impersonation when blocked' do
    let(:blocked_user) { create(:user, state: :blocked) }

    it 'does not allow impersonation' do
      post :create, id: blocked_user.username

      expect(flash[:alert]).to eq 'You cannot impersonate a blocked user'
    end
  end
end
