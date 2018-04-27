require 'spec_helper'

describe EE::API::Helpers do
  include Rack::Test::Methods

  let(:helper) do
    Class.new(Grape::API) do
      helpers EE::API::Helpers
      helpers API::APIGuard::HelperMethods
      helpers API::Helpers
      format :json

      get 'user' do
        current_user ? { id: current_user.id } : { found: false }
      end

      get 'protected' do
        authenticate_by_gitlab_geo_node_token!
      end
    end
  end

  def app
    helper
  end

  describe '#current_user' do
    let(:user) { build(:user, id: 42) }

    before do
      allow(Gitlab::Database::LoadBalancing).to receive(:enable?).and_return(true)
    end

    it 'handles sticking when a user could be found' do
      allow_any_instance_of(API::Helpers).to receive(:initial_current_user).and_return(user)

      expect(Gitlab::Database::LoadBalancing::RackMiddleware)
        .to receive(:stick_or_unstick).with(any_args, :user, 42)

      get 'user'

      expect(JSON.parse(last_response.body)).to eq({ 'id' => user.id })
    end

    it 'does not handle sticking if no user could be found' do
      allow_any_instance_of(API::Helpers).to receive(:initial_current_user).and_return(nil)

      expect(Gitlab::Database::LoadBalancing::RackMiddleware)
        .not_to receive(:stick_or_unstick)

      get 'user'

      expect(JSON.parse(last_response.body)).to eq({ 'found' => false })
    end

    it 'returns the user if one could be found' do
      allow_any_instance_of(API::Helpers).to receive(:initial_current_user).and_return(user)

      get 'user'

      expect(JSON.parse(last_response.body)).to eq({ 'id' => user.id })
    end
  end

  describe '#authenticate_by_gitlab_geo_node_token!' do
    it 'rescues from ::Gitlab::Geo::InvalidDecryptionKeyError' do
      expect_any_instance_of(::Gitlab::Geo::JwtRequestDecoder).to receive(:decode) { raise ::Gitlab::Geo::InvalidDecryptionKeyError }

      header 'Authorization', 'test'
      get 'protected', current_user: 'test'

      expect(JSON.parse(last_response.body)).to eq({ 'message' => 'Gitlab::Geo::InvalidDecryptionKeyError' })
    end

    it 'rescues from ::Gitlab::Geo::InvalidSignatureTimeError' do
      allow_any_instance_of(::Gitlab::Geo::JwtRequestDecoder).to receive(:decode) { raise ::Gitlab::Geo::InvalidSignatureTimeError }

      header 'Authorization', 'test'
      get 'protected', current_user: 'test'

      expect(JSON.parse(last_response.body)).to eq({ 'message' => 'Gitlab::Geo::InvalidSignatureTimeError' })
    end
  end
end
