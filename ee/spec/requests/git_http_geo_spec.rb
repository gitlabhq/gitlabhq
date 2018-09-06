require 'spec_helper'

describe "Git HTTP requests (Geo)" do
  include TermsHelper
  include ::EE::GeoHelpers
  include GitHttpHelpers
  include WorkhorseHelpers
  using RSpec::Parameterized::TableSyntax

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

  context 'git-lfs' do
    context 'API' do
      describe 'POST batch' do
        def make_request
          post url, args, env
        end

        let(:args) { {} }
        let(:url) { "/#{project.full_path}.git/info/lfs/objects/batch" }

        subject do
          make_request
          response
        end

        before do
          allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
          project.update_attribute(:lfs_enabled, true)
          env['Content-Type'] = LfsRequest::CONTENT_TYPE
        end

        context 'operation upload' do
          let(:args) { { 'operation' => 'upload' }.to_json }

          context 'with the correct git-lfs version' do
            before do
              env['User-Agent'] = 'git-lfs/2.4.2 (GitHub; darwin amd64; go 1.10.2)'
            end

            it 'redirects to the primary' do
              is_expected.to have_gitlab_http_status(:redirect)
              redirect_location = "#{primary.url.chomp('/')}#{url}"
              expect(subject.header['Location']).to eq(redirect_location)
            end
          end

          context 'with an incorrect git-lfs version' do
            where(:description, :version) do
              'outdated' | 'git-lfs/2.4.1'
              'unknown'  | 'git-lfs'
            end

            with_them do
              context "that is #{description}" do
                before do
                  env['User-Agent'] = "#{version} (GitHub; darwin amd64; go 1.10.2)"
                end

                it 'is forbidden' do
                  is_expected.to have_gitlab_http_status(:forbidden)
                  expect(json_response['message']).to match(/You need git-lfs version 2.4.2/)
                end
              end
            end
          end
        end

        context 'operation download' do
          let(:user) { create(:user) }
          let(:authorization) { ActionController::HttpAuthentication::Basic.encode_credentials(user.username, user.password) }
          let(:lfs_object) { create(:lfs_object, :with_file) }
          let(:args) do
            {
              'operation' => 'download',
              'objects' => [{ 'oid' => lfs_object.oid, 'size' => lfs_object.size }]
            }.to_json
          end

          before do
            project.add_maintainer(user)
            env['Authorization'] = authorization
          end

          it 'is handled by the secondary' do
            is_expected.to have_gitlab_http_status(:ok)
          end

          where(:description, :version) do
            'outdated' | 'git-lfs/2.4.1'
            'unknown'  | 'git-lfs'
          end

          with_them do
            context "with an #{description} git-lfs version" do
              before do
                env['User-Agent'] = "#{version} (GitHub; darwin amd64; go 1.10.2)"
              end

              it 'is handled by the secondary' do
                is_expected.to have_gitlab_http_status(:ok)
              end
            end
          end
        end
      end
    end

    context 'Locks API' do
      where(:description, :path, :args) do
        'create' | 'info/lfs/locks'          | {}
        'verify' | 'info/lfs/locks/verify'   | {}
        'unlock' | 'info/lfs/locks/1/unlock' | { id: 1 }
      end

      with_them do
        describe "POST #{description}" do
          def make_request
            post url, args, env
          end

          let(:url) { "/#{project.full_path}.git/#{path}" }

          subject do
            make_request
            response
          end

          it 'redirects to the primary' do
            is_expected.to have_gitlab_http_status(:redirect)
            redirect_location = "#{primary.url.chomp('/')}#{url}"
            expect(subject.header['Location']).to eq(redirect_location)
          end
        end
      end
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
