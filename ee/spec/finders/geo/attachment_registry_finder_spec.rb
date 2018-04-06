require 'spec_helper'

describe Geo::AttachmentRegistryFinder, :geo do
  include ::EE::GeoHelpers

  let(:secondary) { create(:geo_node) }

  let(:synced_group) { create(:group) }
  let(:synced_subgroup) { create(:group, parent: synced_group) }
  let(:unsynced_group) { create(:group) }
  let(:synced_project) { create(:project, group: synced_group) }
  let(:unsynced_project) { create(:project, group: unsynced_group, repository_storage: 'broken') }

  let(:upload_1) { create(:upload, model: synced_group) }
  let(:upload_2) { create(:upload, model: unsynced_group) }
  let(:upload_3) { create(:upload, :issuable_upload, model: synced_project) }
  let(:upload_4) { create(:upload, model: unsynced_project) }
  let(:upload_5) { create(:upload, model: synced_project) }
  let(:upload_6) { create(:upload, :personal_snippet_upload) }
  let(:upload_7) { create(:upload, model: synced_subgroup) }
  let(:upload_8) { create(:upload, :object_storage, model: unsynced_project) }
  let(:upload_9) { create(:upload, :object_storage, model: unsynced_group) }
  let(:lfs_object) { create(:lfs_object) }

  subject { described_class.new(current_node: secondary) }

  before do
    stub_current_geo_node(secondary)
  end

  shared_examples 'finds all the things' do
    describe '#find_synced_attachments' do
      it 'delegates to the correct method' do
        expect(subject).to receive("#{method_prefix}_find_synced_attachments".to_sym).and_call_original

        subject.find_synced_attachments
      end

      it 'returns synced avatars, attachment, personal snippets and files' do
        create(:geo_file_registry, :avatar, file_id: upload_1.id)
        create(:geo_file_registry, :avatar, file_id: upload_2.id)
        create(:geo_file_registry, :avatar, file_id: upload_3.id, success: false)
        create(:geo_file_registry, :avatar, file_id: upload_6.id)
        create(:geo_file_registry, :avatar, file_id: upload_7.id)
        create(:geo_file_registry, :lfs, file_id: lfs_object.id)

        synced_attachments = subject.find_synced_attachments

        expect(synced_attachments).to match_ids(upload_1, upload_2, upload_6, upload_7)
      end

      it 'only finds local attachments' do
        create(:geo_file_registry, :avatar, file_id: upload_1.id)
        create(:geo_file_registry, :avatar, file_id: upload_2.id)
        upload_1.update!(store: ObjectStorage::Store::REMOTE)

        synced_attachments = subject.find_synced_attachments

        expect(synced_attachments).to match_ids(upload_2)
      end

      context 'with selective sync by namespace' do
        it 'returns synced avatars, attachment, personal snippets and files' do
          create(:geo_file_registry, :avatar, file_id: upload_1.id)
          create(:geo_file_registry, :avatar, file_id: upload_2.id)
          create(:geo_file_registry, :avatar, file_id: upload_3.id)
          create(:geo_file_registry, :avatar, file_id: upload_4.id)
          create(:geo_file_registry, :avatar, file_id: upload_5.id, success: false)
          create(:geo_file_registry, :avatar, file_id: upload_6.id)
          create(:geo_file_registry, :avatar, file_id: upload_7.id)
          create(:geo_file_registry, :lfs, file_id: lfs_object.id)

          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])

          synced_attachments = subject.find_synced_attachments

          expect(synced_attachments).to match_ids(upload_1, upload_3, upload_6, upload_7)
        end
      end

      context 'with selective sync by shard' do
        it 'returns synced avatars, attachment, personal snippets and files' do
          create(:geo_file_registry, :avatar, file_id: upload_1.id)
          create(:geo_file_registry, :avatar, file_id: upload_2.id)
          create(:geo_file_registry, :avatar, file_id: upload_3.id)
          create(:geo_file_registry, :avatar, file_id: upload_4.id)
          create(:geo_file_registry, :avatar, file_id: upload_5.id, success: false)
          create(:geo_file_registry, :avatar, file_id: upload_6.id)
          create(:geo_file_registry, :avatar, file_id: upload_7.id)
          create(:geo_file_registry, :lfs, file_id: lfs_object.id)

          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['default'])

          synced_attachments = subject.find_synced_attachments

          expect(synced_attachments).to match_ids(upload_1, upload_3, upload_6)
        end
      end
    end

    describe '#find_failed_attachments' do
      it 'delegates to the correct method' do
        expect(subject).to receive("#{method_prefix}_find_failed_attachments".to_sym).and_call_original

        subject.find_failed_attachments
      end

      it 'returns failed avatars, attachment, personal snippets and files' do
        create(:geo_file_registry, :avatar, file_id: upload_1.id)
        create(:geo_file_registry, :avatar, file_id: upload_2.id)
        create(:geo_file_registry, :avatar, file_id: upload_3.id, success: false)
        create(:geo_file_registry, :avatar, file_id: upload_6.id, success: false)
        create(:geo_file_registry, :avatar, file_id: upload_7.id, success: false)
        create(:geo_file_registry, :lfs, file_id: lfs_object.id, success: false)

        failed_attachments = subject.find_failed_attachments

        expect(failed_attachments).to match_ids(upload_3, upload_6, upload_7)
      end

      context 'with selective sync by namespace' do
        it 'returns failed avatars, attachment, personal snippets and files' do
          create(:geo_file_registry, :avatar, file_id: upload_1.id, success: false)
          create(:geo_file_registry, :avatar, file_id: upload_2.id)
          create(:geo_file_registry, :avatar, file_id: upload_3.id, success: false)
          create(:geo_file_registry, :avatar, file_id: upload_4.id, success: false)
          create(:geo_file_registry, :avatar, file_id: upload_5.id)
          create(:geo_file_registry, :avatar, file_id: upload_6.id, success: false)
          create(:geo_file_registry, :avatar, file_id: upload_7.id, success: false)
          create(:geo_file_registry, :lfs, file_id: lfs_object.id, success: false)

          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])

          failed_attachments = subject.find_failed_attachments

          expect(failed_attachments).to match_ids(upload_1, upload_3, upload_6, upload_7)
        end
      end

      context 'with selective sync by shard' do
        it 'returns failed avatars, attachment, personal snippets and files' do
          create(:geo_file_registry, :avatar, file_id: upload_1.id, success: false)
          create(:geo_file_registry, :avatar, file_id: upload_2.id)
          create(:geo_file_registry, :avatar, file_id: upload_3.id, success: false)
          create(:geo_file_registry, :avatar, file_id: upload_4.id, success: false)
          create(:geo_file_registry, :avatar, file_id: upload_5.id)
          create(:geo_file_registry, :avatar, file_id: upload_6.id, success: false)
          create(:geo_file_registry, :avatar, file_id: upload_7.id, success: false)
          create(:geo_file_registry, :lfs, file_id: lfs_object.id, success: false)

          secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['default'])

          failed_attachments = subject.find_failed_attachments

          expect(failed_attachments).to match_ids(upload_1, upload_3, upload_6)
        end
      end
    end

    describe '#find_unsynced_attachments' do
      it 'delegates to the correct method' do
        expect(subject).to receive("#{method_prefix}_find_unsynced_attachments".to_sym).and_call_original

        subject.find_unsynced_attachments(batch_size: 10)
      end

      it 'returns uploads without an entry on the tracking database' do
        create(:geo_file_registry, :avatar, file_id: upload_1.id, success: true)

        uploads = subject.find_unsynced_attachments(batch_size: 10)

        expect(uploads).to match_ids(upload_2, upload_3, upload_4)
      end

      it 'excludes uploads without an entry on the tracking database' do
        create(:geo_file_registry, :avatar, file_id: upload_1.id, success: true)

        uploads = subject.find_unsynced_attachments(batch_size: 10, except_file_ids: [upload_2.id])

        expect(uploads).to match_ids(upload_3, upload_4)
      end

      it 'excludes remote uploads without an entry on the tracking database' do
        create(:geo_file_registry, :avatar, file_id: upload_1.id, success: true)

        uploads = subject.find_unsynced_attachments(batch_size: 10)

        expect(uploads).to match_ids(upload_2, upload_3, upload_4)
      end
    end

    describe '#find_migrated_local_attachments' do
      it 'delegates to the correct method' do
        expect(subject).to receive("#{method_prefix}_find_migrated_local_attachments".to_sym).and_call_original

        subject.find_migrated_local_attachments(batch_size: 100)
      end

      it 'returns uploads stored remotely and successfully synced locally' do
        upload = create(:upload, :object_storage, model: synced_group)
        create(:geo_file_registry, :avatar, file_id: upload.id)

        uploads = subject.find_migrated_local_attachments(batch_size: 100)

        expect(uploads).to match_ids(upload)
      end

      it 'excludes uploads stored remotely, but not synced yet' do
        create(:upload, :object_storage, model: synced_group)

        uploads = subject.find_migrated_local_attachments(batch_size: 100)

        expect(uploads).to be_empty
      end

      it 'excludes synced uploads that are stored locally' do
        create(:geo_file_registry, :avatar, file_id: upload_5.id)

        uploads = subject.find_migrated_local_attachments(batch_size: 100)

        expect(uploads).to be_empty
      end

      it 'excludes except_file_ids' do
        upload_a = create(:upload, :object_storage, model: synced_group)
        upload_b = create(:upload, :object_storage, model: unsynced_group)
        create(:geo_file_registry, :avatar, file_id: upload_a.id, success: true)
        create(:geo_file_registry, :avatar, file_id: upload_b.id, success: true)

        uploads = subject.find_migrated_local_attachments(batch_size: 10, except_file_ids: [upload_a.id])

        expect(uploads).to match_ids(upload_b)
      end
    end
  end

  # Disable transactions via :delete method because a foreign table
  # can't see changes inside a transaction of a different connection.
  context 'FDW', :delete do
    before do
      skip('FDW is not configured') if Gitlab::Database.postgresql? && !Gitlab::Geo::Fdw.enabled?
    end

    include_examples 'finds all the things' do
      let(:method_prefix) { 'fdw' }
    end

    context 'with selective sync' do
      before do
        secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
      end

      it '#find_synced_attachments falls back to legacy queries' do
        expect(subject).to receive(:legacy_find_synced_attachments)

        subject.find_synced_attachments
      end

      it '#find_failed_attachments falls back to legacy queries' do
        expect(subject).to receive(:legacy_find_failed_attachments)

        subject.find_failed_attachments
      end
    end
  end

  context 'Legacy' do
    before do
      allow(Gitlab::Geo::Fdw).to receive(:enabled?).and_return(false)
    end

    include_examples 'finds all the things' do
      let(:method_prefix) { 'legacy' }
    end
  end
end
