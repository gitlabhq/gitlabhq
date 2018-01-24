require 'spec_helper'

describe "Git HTTP requests (Geo)" do
  include ::EE::GeoHelpers
  include GitHttpHelpers
  include WorkhorseHelpers

  set(:project) { create(:project, :repository, :private) }
  set(:primary) { create(:geo_node, :primary) }
  set(:secondary) { create(:geo_node) }

  # Ensure the token always comes from the real time of the request
  let!(:auth_token) { Gitlab::Geo::BaseRequest.new.authorization }

  before do
    stub_licensed_features(geo: true)
    stub_current_geo_node(secondary)
  end

  shared_examples_for 'Geo sync request' do
    subject do
      make_request

      response
    end

    context 'valid Geo JWT token' do
      let(:env) { valid_geo_env }

      it 'returns an OK response' do
        is_expected.to have_gitlab_http_status(:ok)

        expect(response.content_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
        expect(json_response).to include('ShowAllRefs' => true)
      end
    end

    context 'post-dated Geo JWT token' do
      let(:env) { valid_geo_env }

      it { travel_to(2.minutes.ago) { is_expected.to have_gitlab_http_status(:unauthorized) } }
    end

    context 'expired Geo JWT token' do
      let(:env) { valid_geo_env }

      it { travel_to(Time.now + 2.minutes) { is_expected.to have_gitlab_http_status(:unauthorized) } }
    end

    context 'invalid Geo JWT token' do
      let(:env) { geo_env("GL-Geo xxyyzz:12345") }

      it { is_expected.to have_gitlab_http_status(:unauthorized) }
    end

    context 'no Geo JWT token' do
      let(:env) { workhorse_internal_api_request_header }
      it { is_expected.to have_gitlab_http_status(:unauthorized) }
    end

    context 'Geo is unlicensed' do
      let(:env) { valid_geo_env }

      before do
        stub_licensed_features(geo: false)
      end

      it { is_expected.to have_gitlab_http_status(:forbidden) }
    end
  end

  describe 'GET info_refs' do
    def make_request
      get "/#{project.full_path}.git/info/refs", { service: 'git-upload-pack' }, env
    end

    it_behaves_like 'Geo sync request'
  end

  describe 'POST upload_pack' do
    def make_request
      post "/#{project.full_path}.git/git-upload-pack", {}, env
    end

    it_behaves_like 'Geo sync request'
  end

  def valid_geo_env
    geo_env(auth_token)
  end

  def geo_env(authorization)
    env = workhorse_internal_api_request_header
    env['HTTP_AUTHORIZATION'] = authorization

    env
  end
end
