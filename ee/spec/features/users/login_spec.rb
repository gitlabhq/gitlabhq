require 'spec_helper'

describe 'Login' do
  before do
    stub_licensed_features(extended_audit_events: true)
  end

  it 'creates a security event for an invalid password login' do
    user = create(:user, password: 'not-the-default')

    expect { gitlab_sign_in(user) }
      .to change { SecurityEvent.where(entity_id: -1).count }.from(0).to(1)
  end

  it 'creates a security event for an invalid OAuth login' do
    stub_omniauth_saml_config(
      enabled: true,
      auto_link_saml_user: false,
      allow_single_sign_on: ['saml'],
      providers: [mock_saml_config]
    )

    user = create(:omniauth_user, :two_factor, extern_uid: 'my-uid', provider: 'saml')

    expect { gitlab_sign_in_via('saml', user, 'wrong-uid') }
      .to change { SecurityEvent.where(entity_id: -1).count }.from(0).to(1)
  end
end
