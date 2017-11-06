require 'spec_helper'

describe EE::API::Helpers do
  include API::APIGuard::HelperMethods
  include API::Helpers

  let(:options) { {} }
  let(:params) { {} }
  let(:env) do
    {
      'rack.input' => '',
      'REQUEST_METHOD' => 'GET'
    }
  end
  let(:header) { }

  before do
    allow(Gitlab::Database::LoadBalancing).to receive(:enable?).and_return(true)
  end

  describe '#current_user' do
    let(:user) { build(:user, id: 42) }

    it 'handles sticking when a user could be found' do
      allow_any_instance_of(API::Helpers).to receive(:initial_current_user).and_return(user)

      expect(Gitlab::Database::LoadBalancing::RackMiddleware)
        .to receive(:stick_or_unstick).with(env, :user, 42)

      current_user
    end

    it 'does not handle sticking if no user could be found' do
      allow_any_instance_of(API::Helpers).to receive(:initial_current_user).and_return(nil)

      expect(Gitlab::Database::LoadBalancing::RackMiddleware)
        .not_to receive(:stick_or_unstick)

      current_user
    end

    it 'returns the user if one could be found' do
      allow_any_instance_of(API::Helpers).to receive(:initial_current_user).and_return(user)

      expect(current_user).to eq(user)
    end
  end
end
