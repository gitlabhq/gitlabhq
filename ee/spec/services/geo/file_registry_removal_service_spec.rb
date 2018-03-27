require 'spec_helper'

describe Geo::FileRegistryRemovalService do
  include ::EE::GeoHelpers

  set(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)

    allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(true)
  end

  describe '#execute' do
    it 'delegates log_error to the Geo logger' do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(false)
      expect(Gitlab::Geo::Logger).to receive(:error)

      described_class.new(:lfs, 99).execute
    end

    shared_examples 'removes' do
      subject(:service) { described_class.new(file_registry.file_type, file_registry.file_id) }

      it 'file from disk' do
        expect do
          service.execute
        end.to change { File.exist?(file_path) }.from(true).to(false)
      end

      it 'registry when file was deleted successfully' do
        expect do
          service.execute
        end.to change(Geo::FileRegistry, :count).by(-1)
      end
    end

    context 'with LFS object' do
      let!(:lfs_object) { create(:lfs_object, :with_file) }
      let!(:file_registry) { create(:geo_file_registry, :lfs, file_id: lfs_object.id) }
      let!(:file_path) { lfs_object.file.path }

      it_behaves_like 'removes'

      context 'migrated to object storage' do
        before do
          stub_lfs_object_storage
          lfs_object.update_column(:file_store, LfsObjectUploader::Store::REMOTE)
        end

        it_behaves_like 'removes'
      end
    end

    context 'with job artifact' do
      let!(:job_artifact) { create(:ci_job_artifact, :archive) }
      let!(:file_registry) { create(:geo_file_registry, :job_artifact, file_id: job_artifact.id) }
      let!(:file_path) { job_artifact.file.path }

      it_behaves_like 'removes'

      context 'migrated to object storage' do
        before do
          stub_artifacts_object_storage
          job_artifact.update_column(:file_store, JobArtifactUploader::Store::REMOTE)
        end

        it_behaves_like 'removes'
      end
    end

    context 'with avatar' do
      let!(:upload) { create(:user, :with_avatar).avatar.upload }
      let!(:file_registry) { create(:geo_file_registry, :avatar, file_id: upload.id) }
      let!(:file_path) { upload.build_uploader.file.path }

      it_behaves_like 'removes'

      context 'migrated to object storage' do
        before do
          stub_uploads_object_storage(AvatarUploader)
          upload.update_column(:store, AvatarUploader::Store::REMOTE)
        end

        it_behaves_like 'removes'
      end
    end

    context 'with attachment' do
      let!(:upload) { create(:note, :with_attachment).attachment.upload }
      let!(:file_registry) { create(:geo_file_registry, :attachment, file_id: upload.id) }
      let!(:file_path) { upload.build_uploader.file.path }

      it_behaves_like 'removes'

      context 'migrated to object storage' do
        before do
          stub_uploads_object_storage(AttachmentUploader)
          upload.update_column(:store, AttachmentUploader::Store::REMOTE)
        end

        it_behaves_like 'removes'
      end
    end

    context 'with file' do # TODO
      let!(:upload) { create(:user, :with_avatar).avatar.upload }
      let!(:file_registry) { create(:geo_file_registry, :avatar, file_id: upload.id) }
      let!(:file_path) { upload.build_uploader.file.path }

      it_behaves_like 'removes'

      context 'migrated to object storage' do
        before do
          stub_uploads_object_storage(AvatarUploader)
          upload.update_column(:store, AvatarUploader::Store::REMOTE)
        end

        it_behaves_like 'removes'
      end
    end

    context 'with namespace_file' do
      set(:group) { create(:group) }
      let(:file) { fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png') }
      let!(:upload) do
        NamespaceFileUploader.new(group).store!(file)
        Upload.find_by(model: group, uploader: NamespaceFileUploader)
      end

      let!(:file_registry) { create(:geo_file_registry, :namespace_file, file_id: upload.id) }
      let!(:file_path) { upload.build_uploader.file.path }

      it_behaves_like 'removes'

      context 'migrated to object storage' do
        before do
          stub_uploads_object_storage(NamespaceFileUploader)
          upload.update_column(:store, NamespaceFileUploader::Store::REMOTE)
        end

        it_behaves_like 'removes'
      end
    end

    context 'with personal_file' do
      let(:snippet) { create(:personal_snippet) }
      let(:file) { fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png') }
      let!(:upload) do
        PersonalFileUploader.new(snippet).store!(file)
        Upload.find_by(model: snippet, uploader: PersonalFileUploader)
      end
      let!(:file_registry) { create(:geo_file_registry, :personal_file, file_id: upload.id) }
      let!(:file_path) { upload.build_uploader.file.path }

      it_behaves_like 'removes'

      context 'migrated to object storage' do
        before do
          stub_uploads_object_storage(PersonalFileUploader)
          upload.update_column(:store, PersonalFileUploader::Store::REMOTE)
        end

        it_behaves_like 'removes'
      end
    end
  end
end
