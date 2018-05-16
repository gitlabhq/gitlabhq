require 'spec_helper'

describe API::Geo do
  include TermsHelper
  include ApiHelpers
  include ::EE::GeoHelpers

  set(:admin) { create(:admin) }
  set(:user) { create(:user) }
  set(:primary_node) { create(:geo_node, :primary) }
  set(:secondary_node) { create(:geo_node) }
  let(:geo_token_header) do
    { 'X-Gitlab-Token' => secondary_node.system_hook.token }
  end

  before do
    stub_current_geo_node(secondary_node)
  end

  shared_examples 'with terms enforced' do
    before do
      enforce_terms
    end

    it 'responds with 200' do
      request

      expect(response).to have_gitlab_http_status(200)
    end
  end

  describe 'GET /geo/transfers/attachment/1' do
    let(:note) { create(:note, :with_attachment) }
    let(:upload) { Upload.find_by(model: note, uploader: 'AttachmentUploader') }
    let(:transfer) { Gitlab::Geo::FileTransfer.new(:attachment, upload) }
    let(:req_header) { Gitlab::Geo::TransferRequest.new(transfer.request_data).headers }

    before do
      allow_any_instance_of(Gitlab::Geo::TransferRequest).to receive(:requesting_node).and_return(secondary_node)
    end

    it 'responds with 401 with invalid auth header' do
      get api("/geo/transfers/attachment/#{upload.id}"), nil, Authorization: 'Test'

      expect(response).to have_gitlab_http_status(401)
    end

    context 'attachment file exists' do
      subject(:request) { get api("/geo/transfers/attachment/#{upload.id}"), nil, req_header }

      it 'responds with 200 with X-Sendfile' do
        request

        expect(response).to have_gitlab_http_status(200)
        expect(response.headers['Content-Type']).to eq('application/octet-stream')
        expect(response.headers['X-Sendfile']).to eq(note.attachment.path)
      end

      it_behaves_like 'with terms enforced'
    end

    context 'attachment does not exist' do
      it 'responds with 404' do
        get api("/geo/transfers/attachment/100000"), nil, req_header

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET /geo/transfers/avatar/1' do
    let(:user) { create(:user, avatar: fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png')) }
    let(:upload) { Upload.find_by(model: user, uploader: 'AvatarUploader') }
    let(:transfer) { Gitlab::Geo::FileTransfer.new(:avatar, upload) }
    let(:req_header) { Gitlab::Geo::TransferRequest.new(transfer.request_data).headers }

    before do
      allow_any_instance_of(Gitlab::Geo::TransferRequest).to receive(:requesting_node).and_return(secondary_node)
    end

    it 'responds with 401 with invalid auth header' do
      get api("/geo/transfers/avatar/#{upload.id}"), nil, Authorization: 'Test'

      expect(response).to have_gitlab_http_status(401)
    end

    context 'avatar file exists' do
      subject(:request) { get api("/geo/transfers/avatar/#{upload.id}"), nil, req_header }

      it 'responds with 200 with X-Sendfile' do
        request

        expect(response).to have_gitlab_http_status(200)
        expect(response.headers['Content-Type']).to eq('application/octet-stream')
        expect(response.headers['X-Sendfile']).to eq(user.avatar.path)
      end

      it_behaves_like 'with terms enforced'
    end

    context 'avatar does not exist' do
      it 'responds with 404' do
        get api("/geo/transfers/avatar/100000"), nil, req_header

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET /geo/transfers/file/1' do
    let(:project) { create(:project) }
    let(:upload) { Upload.find_by(model: project, uploader: 'FileUploader') }
    let(:transfer) { Gitlab::Geo::FileTransfer.new(:file, upload) }
    let(:req_header) { Gitlab::Geo::TransferRequest.new(transfer.request_data).headers }

    before do
      allow_any_instance_of(Gitlab::Geo::TransferRequest).to receive(:requesting_node).and_return(secondary_node)
      FileUploader.new(project).store!(fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png'))
    end

    it 'responds with 401 with invalid auth header' do
      get api("/geo/transfers/file/#{upload.id}"), nil, Authorization: 'Test'

      expect(response).to have_gitlab_http_status(401)
    end

    context 'when the Upload record exists' do
      context 'when the file exists' do
        subject(:request) { get api("/geo/transfers/file/#{upload.id}"), nil, req_header }

        it 'responds with 200 with X-Sendfile' do
          request

          expect(response).to have_gitlab_http_status(200)
          expect(response.headers['Content-Type']).to eq('application/octet-stream')
          expect(response.headers['X-Sendfile']).to end_with('dk.png')
        end

        it_behaves_like 'with terms enforced'
      end

      context 'file does not exist' do
        it 'responds with 404 and a specific geo code' do
          File.unlink(upload.absolute_path)

          get api("/geo/transfers/file/#{upload.id}"), nil, req_header

          expect(response).to have_gitlab_http_status(404)
          expect(json_response['geo_code']).to eq(Gitlab::Geo::FileUploader::FILE_NOT_FOUND_GEO_CODE)
        end
      end
    end

    context 'when the Upload record does not exist' do
      it 'responds with 404' do
        get api("/geo/transfers/file/100000"), nil, req_header

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET /geo/transfers/lfs/1' do
    let(:lfs_object) { create(:lfs_object, :with_file) }
    let(:req_header) do
      transfer = Gitlab::Geo::LfsTransfer.new(lfs_object)
      Gitlab::Geo::TransferRequest.new(transfer.request_data).headers
    end

    before do
      allow_any_instance_of(Gitlab::Geo::TransferRequest).to receive(:requesting_node).and_return(secondary_node)
    end

    it 'responds with 401 with invalid auth header' do
      get api("/geo/transfers/lfs/#{lfs_object.id}"), nil, Authorization: 'Test'

      expect(response).to have_gitlab_http_status(401)
    end

    context 'LFS object exists' do
      context 'file exists' do
        subject(:request) { get api("/geo/transfers/lfs/#{lfs_object.id}"), nil, req_header }

        it 'responds with 200 with X-Sendfile' do
          request

          expect(response).to have_gitlab_http_status(200)
          expect(response.headers['Content-Type']).to eq('application/octet-stream')
          expect(response.headers['X-Sendfile']).to eq(lfs_object.file.path)
        end

        it_behaves_like 'with terms enforced'
      end

      context 'file does not exist' do
        it 'responds with 404 and a specific geo code' do
          File.unlink(lfs_object.file.path)

          get api("/geo/transfers/lfs/#{lfs_object.id}"), nil, req_header

          expect(response).to have_gitlab_http_status(404)
          expect(json_response['geo_code']).to eq(Gitlab::Geo::FileUploader::FILE_NOT_FOUND_GEO_CODE)
        end
      end
    end

    context 'LFS object does not exist' do
      it 'responds with 404' do
        get api("/geo/transfers/lfs/100000"), nil, req_header

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET /geo/status', :postgresql do
    let(:geo_base_request) { Gitlab::Geo::BaseRequest.new }

    subject(:request) { get api('/geo/status'), nil, geo_base_request.headers }

    it 'responds with 401 with invalid auth header' do
      get api('/geo/status'), nil, Authorization: 'Test'

      expect(response).to have_gitlab_http_status(401)
    end

    it 'responds with 401 when the db_key_base is wrong' do
      allow_any_instance_of(Gitlab::Geo::JwtRequestDecoder).to receive(:decode).and_raise(Gitlab::Geo::InvalidDecryptionKeyError)

      request

      expect(response).to have_gitlab_http_status(401)
    end

    context 'when requesting secondary node with valid auth header' do
      before do
        stub_current_geo_node(secondary_node)
        allow(geo_base_request).to receive(:requesting_node) { primary_node }
        allow(::GeoNodeStatus).to receive(:fast_current_node_status).and_return(::GeoNodeStatus.current_node_status)
      end

      it 'responds with 200' do
        request

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/geo_node_status', dir: 'ee')
      end

      it_behaves_like 'with terms enforced'
    end

    context 'when requesting primary node with valid auth header' do
      before do
        stub_current_geo_node(primary_node)
        allow(geo_base_request).to receive(:requesting_node) { secondary_node }
      end

      it 'responds with 200' do
        request

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/geo_node_status', dir: 'ee')
      end

      it_behaves_like 'with terms enforced'
    end
  end
end
