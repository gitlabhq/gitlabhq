require 'spec_helper'

describe Geo::FileDownloadService do
  include ::EE::GeoHelpers

  set(:primary)  { create(:geo_node, :primary) }
  set(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)

    allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(true)
  end

  describe '#execute' do
    context 'user avatar' do
      let(:user) { create(:user, avatar: fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png')) }
      let(:upload) { Upload.find_by(model: user, uploader: 'AvatarUploader') }

      subject(:execute!) { described_class.new(:avatar, upload.id).execute }

      it 'downloads a user avatar' do
        stub_transfer(Gitlab::Geo::FileTransfer, 100)

        expect { execute! }.to change { Geo::FileRegistry.synced.count }.by(1)
      end

      it 'registers when the download fails' do
        stub_transfer(Gitlab::Geo::FileTransfer, -1)

        expect { execute! }.to change { Geo::FileRegistry.failed.count }.by(1)
        expect(Geo::FileRegistry.last.retry_count).to eq(1)
        expect(Geo::FileRegistry.last.retry_at).to be_present
      end

      it 'registers when the download fails with some other error' do
        stub_transfer(Gitlab::Geo::FileTransfer, nil)

        expect { execute! }.to change { Geo::FileRegistry.failed.count }.by(1)
      end
    end

    context 'group avatar' do
      let(:group) { create(:group, avatar: fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png')) }
      let(:upload) { Upload.find_by(model: group, uploader: 'AvatarUploader') }

      subject(:execute!) { described_class.new(:avatar, upload.id).execute }

      it 'downloads a group avatar' do
        stub_transfer(Gitlab::Geo::FileTransfer, 100)

        expect { execute! }.to change { Geo::FileRegistry.synced.count }.by(1)
      end

      it 'registers when the download fails' do
        stub_transfer(Gitlab::Geo::FileTransfer, -1)

        expect { execute! }.to change { Geo::FileRegistry.failed.count }.by(1)
      end
    end

    context 'project avatar' do
      let(:project) { create(:project, avatar: fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png')) }
      let(:upload) { Upload.find_by(model: project, uploader: 'AvatarUploader') }

      subject(:execute!) { described_class.new(:avatar, upload.id).execute }

      it 'downloads a project avatar' do
        stub_transfer(Gitlab::Geo::FileTransfer, 100)

        expect { execute! }.to change { Geo::FileRegistry.synced.count }.by(1)
      end

      it 'registers when the download fails' do
        stub_transfer(Gitlab::Geo::FileTransfer, -1)

        expect { execute! }.to change { Geo::FileRegistry.failed.count }.by(1)
      end
    end

    context 'with an attachment' do
      let(:note) { create(:note, :with_attachment) }
      let(:upload) { Upload.find_by(model: note, uploader: 'AttachmentUploader') }

      subject(:execute!) { described_class.new(:attachment, upload.id).execute }

      it 'downloads the attachment' do
        stub_transfer(Gitlab::Geo::FileTransfer, 100)

        expect { execute! }.to change { Geo::FileRegistry.synced.count }.by(1)
      end

      it 'registers when the download fails' do
        stub_transfer(Gitlab::Geo::FileTransfer, -1)

        expect { execute! }.to change { Geo::FileRegistry.failed.count }.by(1)
      end
    end

    context 'with a snippet' do
      let(:upload) { create(:upload, :personal_snippet_upload) }

      subject(:execute!) { described_class.new(:personal_file, upload.id).execute }

      it 'downloads the file' do
        stub_transfer(Gitlab::Geo::FileTransfer, 100)

        expect { execute! }.to change { Geo::FileRegistry.synced.count }.by(1)
      end

      it 'registers when the download fails' do
        stub_transfer(Gitlab::Geo::FileTransfer, -1)

        expect { execute! }.to change { Geo::FileRegistry.failed.count }.by(1)
      end
    end

    context 'with file upload' do
      let(:project) { create(:project) }
      let(:upload) { Upload.find_by(model: project, uploader: 'FileUploader') }

      subject { described_class.new(:file, upload.id) }

      before do
        FileUploader.new(project).store!(fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png'))
      end

      it 'downloads the file' do
        stub_transfer(Gitlab::Geo::FileTransfer, 100)

        expect { subject.execute }.to change { Geo::FileRegistry.synced.count }.by(1)
      end

      it 'registers when the download fails' do
        stub_transfer(Gitlab::Geo::FileTransfer, -1)

        expect { subject.execute }.to change { Geo::FileRegistry.failed.count }.by(1)
      end
    end

    context 'with namespace file upload' do
      let(:group) { create(:group) }
      let(:upload) { Upload.find_by(model: group, uploader: 'NamespaceFileUploader') }

      subject { described_class.new(:file, upload.id) }

      before do
        NamespaceFileUploader.new(group).store!(fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png'))
      end

      it 'downloads the file' do
        stub_transfer(Gitlab::Geo::FileTransfer, 100)

        expect { subject.execute }.to change { Geo::FileRegistry.synced.count }.by(1)
      end

      it 'registers when the download fails' do
        stub_transfer(Gitlab::Geo::FileTransfer, -1)

        expect { subject.execute }.to change { Geo::FileRegistry.failed.count }.by(1)
      end
    end

    context 'LFS object' do
      let(:lfs_object) { create(:lfs_object) }

      subject { described_class.new(:lfs, lfs_object.id) }

      it 'downloads an LFS object' do
        stub_transfer(Gitlab::Geo::LfsTransfer, 100)

        expect { subject.execute }.to change { Geo::FileRegistry.synced.count }.by(1)
      end

      it 'registers when the download fails' do
        stub_transfer(Gitlab::Geo::LfsTransfer, -1)

        expect { subject.execute }.to change { Geo::FileRegistry.failed.count }.by(1)
      end

      it 'logs a message' do
        stub_transfer(Gitlab::Geo::LfsTransfer, 100)

        expect(Gitlab::Geo::Logger).to receive(:info).with(hash_including(:message, :download_time_s, success: true, bytes_downloaded: 100)).and_call_original

        subject.execute
      end
    end

    context 'job artifacts' do
      let(:job_artifact) { create(:ci_job_artifact) }

      subject { described_class.new(:job_artifact, job_artifact.id) }

      it 'downloads a job artifact' do
        stub_transfer(Gitlab::Geo::JobArtifactTransfer, 100)

        expect { subject.execute }.to change { Geo::JobArtifactRegistry.synced.count }.by(1)
      end

      it 'registers when the download fails' do
        stub_transfer(Gitlab::Geo::JobArtifactTransfer, -1)

        expect { subject.execute }.to change { Geo::JobArtifactRegistry.failed.count }.by(1)
      end

      it 'logs a message' do
        stub_transfer(Gitlab::Geo::JobArtifactTransfer, 100)

        expect(Gitlab::Geo::Logger).to receive(:info).with(hash_including(:message, :download_time_s, success: true, bytes_downloaded: 100)).and_call_original

        subject.execute
      end
    end

    context 'bad object type' do
      it 'raises an error' do
        expect { described_class.new(:bad, 1).execute }.to raise_error(NameError)
      end
    end

    def stub_transfer(kls, result)
      instance = double("(instance of #{kls})", download_from_primary: result)
      allow(kls).to receive(:new).and_return(instance)
    end
  end
end
