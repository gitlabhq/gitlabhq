require 'spec_helper'

describe Geo::FileUploadService do
  set(:node) { create(:geo_node, :primary) }

  describe '#execute' do
    context 'user avatar' do
      let(:user) { create(:user, avatar: fixture_file_upload('spec/fixtures/dk.png', 'image/png')) }
      let(:upload) { Upload.find_by(model: user, uploader: 'AvatarUploader') }
      let(:params) { { id: upload.id, type: 'avatar' } }
      let(:file_transfer) { Gitlab::Geo::FileTransfer.new(:avatar, upload) }
      let(:transfer_request) { Gitlab::Geo::TransferRequest.new(file_transfer.request_data) }
      let(:req_header) { transfer_request.headers['Authorization'] }

      it 'sends avatar file' do
        service = described_class.new(params, req_header)

        response = service.execute

        expect(response[:code]).to eq(:ok)
        expect(response[:file].path).to eq(user.avatar.path)
      end

      it 'returns nil if no authorization' do
        service = described_class.new(params, nil)

        expect(service.execute).to be_nil
      end
    end

    context 'group avatar' do
      let(:group) { create(:group, avatar: fixture_file_upload('spec/fixtures/dk.png', 'image/png')) }
      let(:upload) { Upload.find_by(model: group, uploader: 'AvatarUploader') }
      let(:params) { { id: upload.id, type: 'avatar' } }
      let(:file_transfer) { Gitlab::Geo::FileTransfer.new(:avatar, upload) }
      let(:transfer_request) { Gitlab::Geo::TransferRequest.new(file_transfer.request_data) }
      let(:req_header) { transfer_request.headers['Authorization'] }

      it 'sends avatar file' do
        service = described_class.new(params, req_header)

        response = service.execute

        expect(response[:code]).to eq(:ok)
        expect(response[:file].path).to eq(group.avatar.path)
      end

      it 'returns nil if no authorization' do
        service = described_class.new(params, nil)

        expect(service.execute).to be_nil
      end
    end

    context 'project avatar' do
      let(:project) { create(:project, avatar: fixture_file_upload('spec/fixtures/dk.png', 'image/png')) }
      let(:upload) { Upload.find_by(model: project, uploader: 'AvatarUploader') }
      let(:params) { { id: upload.id, type: 'avatar' } }
      let(:file_transfer) { Gitlab::Geo::FileTransfer.new(:avatar, upload) }
      let(:transfer_request) { Gitlab::Geo::TransferRequest.new(file_transfer.request_data) }
      let(:req_header) { transfer_request.headers['Authorization'] }

      it 'sends avatar file' do
        service = described_class.new(params, req_header)

        response = service.execute

        expect(response[:code]).to eq(:ok)
        expect(response[:file].path).to eq(project.avatar.path)
      end

      it 'returns nil if no authorization' do
        service = described_class.new(params, nil)

        expect(service.execute).to be_nil
      end
    end

    context 'attachment' do
      let(:note) { create(:note, :with_attachment) }
      let(:upload) { Upload.find_by(model: note, uploader: 'AttachmentUploader') }
      let(:params) { { id: upload.id, type: 'attachment' } }
      let(:file_transfer) { Gitlab::Geo::FileTransfer.new(:attachment, upload) }
      let(:transfer_request) { Gitlab::Geo::TransferRequest.new(file_transfer.request_data) }
      let(:req_header) { transfer_request.headers['Authorization'] }

      it 'sends attachment file' do
        service = described_class.new(params, req_header)

        response = service.execute

        expect(response[:code]).to eq(:ok)
        expect(response[:file].path).to eq(note.attachment.path)
      end

      it 'returns nil if no authorization' do
        service = described_class.new(params, nil)

        expect(service.execute).to be_nil
      end
    end

    context 'file upload' do
      let(:project) { create(:project) }
      let(:upload) { Upload.find_by(model: project, uploader: 'FileUploader') }
      let(:params) { { id: upload.id, type: 'file' } }
      let(:file_transfer) { Gitlab::Geo::FileTransfer.new(:file, upload) }
      let(:transfer_request) { Gitlab::Geo::TransferRequest.new(file_transfer.request_data) }
      let(:req_header) { transfer_request.headers['Authorization'] }
      let(:file) { fixture_file_upload('spec/fixtures/dk.png', 'image/png') }

      before do
        FileUploader.new(project).store!(file)
      end

      it 'sends the file' do
        service = described_class.new(params, req_header)

        response = service.execute

        expect(response[:code]).to eq(:ok)
        expect(response[:file].path).to end_with('dk.png')
      end

      it 'returns nil if no authorization' do
        service = described_class.new(params, nil)

        expect(service.execute).to be_nil
      end
    end

    context 'namespace file upload' do
      let(:group) { create(:group) }
      let(:upload) { Upload.find_by(model: group, uploader: 'NamespaceFileUploader') }
      let(:params) { { id: upload.id, type: 'file' } }
      let(:file_transfer) { Gitlab::Geo::FileTransfer.new(:file, upload) }
      let(:transfer_request) { Gitlab::Geo::TransferRequest.new(file_transfer.request_data) }
      let(:req_header) { transfer_request.headers['Authorization'] }
      let(:file) { fixture_file_upload('spec/fixtures/dk.png', 'image/png') }

      before do
        NamespaceFileUploader.new(group).store!(file)
      end

      it 'sends the file' do
        service = described_class.new(params, req_header)

        response = service.execute

        expect(response[:code]).to eq(:ok)
        expect(response[:file].path).to end_with('dk.png')
      end

      it 'returns nil if no authorization' do
        service = described_class.new(params, nil)

        expect(service.execute).to be_nil
      end
    end

    context 'LFS Object' do
      let(:lfs_object) { create(:lfs_object, :with_file) }
      let(:params) { { id: lfs_object.id, type: 'lfs' } }
      let(:lfs_transfer) { Gitlab::Geo::LfsTransfer.new(lfs_object) }
      let(:transfer_request) { Gitlab::Geo::TransferRequest.new(lfs_transfer.request_data) }
      let(:req_header) { transfer_request.headers['Authorization'] }

      it 'sends LFS file' do
        service = described_class.new(params, req_header)

        response = service.execute

        expect(response[:code]).to eq(:ok)
        expect(response[:file].path).to eq(lfs_object.file.path)
      end

      it 'returns nil if no authorization' do
        service = described_class.new(params, nil)

        expect(service.execute).to be_nil
      end
    end

    context 'job artifact' do
      let(:job_artifact) { create(:ci_job_artifact, :with_file) }
      let(:params) { { id: job_artifact.id, type: 'job_artifact' } }
      let(:job_artifact_transfer) { Gitlab::Geo::JobArtifactTransfer.new(job_artifact) }
      let(:transfer_request) { Gitlab::Geo::TransferRequest.new(job_artifact_transfer.request_data) }
      let(:req_header) { transfer_request.headers['Authorization'] }

      it 'sends job artifact file' do
        service = described_class.new(params, req_header)

        response = service.execute

        expect(response[:code]).to eq(:ok)
        expect(response[:file].path).to eq(job_artifact.file.path)
      end

      it 'returns nil if no authorization' do
        service = described_class.new(params, nil)

        expect(service.execute).to be_nil
      end
    end

    context 'import export archive' do
      let(:project) { create(:project) }
      let(:upload) { Upload.find_by(model: project, uploader: 'ImportExportUploader') }
      let(:params) { { id: upload.id, type: 'import_export' } }
      let(:file_transfer) { Gitlab::Geo::FileTransfer.new(:import_export, upload) }
      let(:transfer_request) { Gitlab::Geo::TransferRequest.new(file_transfer.request_data) }
      let(:req_header) { transfer_request.headers['Authorization'] }
      let(:file) { fixture_file_upload('spec/fixtures/project_export.tar.gz') }

      before do
        ImportExportUploader.new(project).store!(file)
      end

      it 'sends the file' do
        service = described_class.new(params, req_header)

        response = service.execute

        expect(response[:code]).to eq(:ok)
        expect(response[:file].path).to end_with('tar.gz')
      end

      it 'returns nil if no authorization' do
        service = described_class.new(params, nil)

        expect(service.execute).to be_nil
      end
    end
  end
end
