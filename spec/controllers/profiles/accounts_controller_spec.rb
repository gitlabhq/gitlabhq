require 'spec_helper'

describe Profiles::AccountsController do
  let(:user) { create(:omniauth_user, provider: 'saml') }

  before do
    sign_in(user)
  end

  it 'does not allow to unlink SAML connected account' do
    identity = user.identities.last
    delete :unlink, provider: 'saml'
    updated_user = User.find(user.id)

    expect(response).to have_http_status(302)
    expect(updated_user.identities.size).to eq(1)
    expect(updated_user.identities).to include(identity)
  end

  it 'does allow to delete other linked accounts' do
    user.identities.create(provider: 'twitter', extern_uid: 'twitter_123')

    expect { delete :unlink, provider: 'twitter' }.to change(Identity.all, :size).by(-1)
  end
end
