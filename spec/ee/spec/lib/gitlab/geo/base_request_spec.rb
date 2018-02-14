require 'spec_helper'

describe Gitlab::Geo::BaseRequest, :geo do
  include ::EE::GeoHelpers

  let(:geo_node) { create(:geo_node) }

  before do
    stub_current_geo_node(geo_node)
  end

  describe '#authorization' do
    let(:request) { described_class.new }
    let(:token) { request.authorization }
    let(:data) { token.split(' ').second.split(':') }
    let(:access_key) { data.first }
    let(:encoded_jwt) { data.second }
    let(:jwt) { JWT.decode(encoded_jwt, geo_node.secret_access_key) }

    it 'token is formatted properly' do
      expect(access_key).to eq(geo_node.access_key)
      expect(token).to start_with(Gitlab::Geo::BaseRequest::GITLAB_GEO_AUTH_TOKEN_TYPE)
    end

    it 'defaults to 1-minute expiration time' do
      Timecop.freeze do
        expect(jwt.first['exp']).to eq((Time.now + 1.minute).to_i)
      end
    end
  end
end
