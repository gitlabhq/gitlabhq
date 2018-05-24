require 'spec_helper'

describe Gitlab::Auth::GroupSaml::FailureHandler do
  include Gitlab::Routing

  let(:parent_handler) { double }
  let(:user) { create(:user) }
  let(:saml_provider) { create(:saml_provider) }
  let(:group) { saml_provider.group }
  let(:warden) { Warden::Proxy.new({}, Warden::Manager.new(nil)) }

  subject { described_class.new(parent_handler) }

  def failure_env(path, strategy)
    params = {
      'omniauth.error.strategy' => strategy,
      'devise.mapping' => Devise.mappings[:user],
      'warden' => warden
    }
    Rack::MockRequest.env_for(path, params)
  end

  def sign_in
    warden.set_user(user, scope: :user)
  end

  before do
    sign_in
  end

  it 'calls Groups::OmniauthCallbacksController#failure for GroupSaml' do
    strategy = OmniAuth::Strategies::GroupSaml.new({})
    callback_path = callback_group_saml_providers_path(group)
    env = failure_env(callback_path, strategy)

    expect_any_instance_of(Groups::OmniauthCallbacksController).to receive(:failure).and_call_original

    subject.call(env)
  end

  it 'falls back to parent on_failure handler' do
    env = failure_env('/', double)

    expect(parent_handler).to receive(:call).with(env)

    subject.call(env)
  end
end
