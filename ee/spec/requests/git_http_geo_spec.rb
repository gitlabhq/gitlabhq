require 'spec_helper'

describe "Git HTTP requests (Geo)" do
  include TermsHelper
  include ::EE::GeoHelpers
  include GitHttpHelpers
  include WorkhorseHelpers

  set(:project) { create(:project, :repository, :private) }
  set(:primary) { create(:geo_node, :primary) }
  set(:secondary) { create(:geo_node) }

  # Ensure the token always comes from the real time of the request
  let!(:auth_token) { Gitlab::Geo::BaseRequest.new.authorization }

  let(:env) { valid_geo_env }

  before do
    stub_licensed_features(geo: true)
    stub_current_geo_node(secondary)
  end

  shared_examples_for 'Geo sync request' do
    subject do
      make_request
      response
    end

    context 'post-dated Geo JWT token' do
      it { travel_to(11.minutes.ago) { is_expected.to have_gitlab_http_status(:unauthorized) } }
    end

    context 'expired Geo JWT token' do
      it { travel_to(Time.now + 11.minutes) { is_expected.to have_gitlab_http_status(:unauthorized) } }
    end

    context 'invalid Geo JWT token' do
      let(:env) { geo_env("GL-Geo xxyyzz:12345") }

      it { is_expected.to have_gitlab_http_status(:unauthorized) }
    end

    context 'valid Geo JWT token' do
      it 'returns an OK response' do
        is_expected.to have_gitlab_http_status(:ok)

        expect(response.content_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
        expect(json_response).to include('ShowAllRefs' => true)
      end
    end

    context 'no Geo JWT token' do
      let(:env) { workhorse_internal_api_request_header }
      it { is_expected.to have_gitlab_http_status(:unauthorized) }
    end

    context 'Geo is unlicensed' do
      before do
        stub_licensed_features(geo: false)
      end

      it { is_expected.to have_gitlab_http_status(:forbidden) }
    end
  end

  describe 'GET info_refs' do
    context 'git pull' do
      def make_request
        get "/#{project.full_path}.git/info/refs", { service: 'git-upload-pack' }, env
      end

      it_behaves_like 'Geo sync request'

      context 'when terms are enforced' do
        before do
          enforce_terms
        end

        it_behaves_like 'Geo sync request'
      end
    end

    context 'git push' do
      def make_request
        get url, { service: 'git-receive-pack' }, env
      end

      let(:url) { "/#{project.full_path}.git/info/refs" }

      subject do
        make_request
        response
      end

      it 'redirects to the primary' do
        is_expected.to have_gitlab_http_status(:redirect)
        redirect_location = "#{primary.url.chomp('/')}#{url}?service=git-receive-pack"
        expect(subject.header['Location']).to eq(redirect_location)
      end
    end
  end

  describe 'POST upload_pack' do
    def make_request
      post "/#{project.full_path}.git/git-upload-pack", {}, env
    end

    it_behaves_like 'Geo sync request'

    context 'when terms are enforced' do
      before do
        enforce_terms
      end

      it_behaves_like 'Geo sync request'
    end
  end

  def valid_geo_env
    geo_env(auth_token)
  end

  def geo_env(authorization)
    workhorse_internal_api_request_header.tap do |env|
      env['HTTP_AUTHORIZATION'] = authorization
    end
  end
end
