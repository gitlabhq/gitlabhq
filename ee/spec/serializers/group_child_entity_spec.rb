require 'spec_helper'

describe GroupChildEntity do
  include ExternalAuthorizationServiceHelpers

  let(:user) { create(:user) }
  let(:request) { double('request') }
  let(:entity) { described_class.new(object, request: request) }
  subject(:json) { entity.as_json }

  before do
    allow(request).to receive(:current_user).and_return(user)
  end

  describe 'for a project with external authorization enabled' do
    let(:object) do
      create(:project, :with_avatar,
             description: 'Awesomeness')
    end

    before do
      enable_external_authorization_service_check
      object.add_master(user)
    end

    it 'does not hit the external authorization service' do
      expect(EE::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

      expect(json[:can_edit]).to eq(false)
    end
  end
end
