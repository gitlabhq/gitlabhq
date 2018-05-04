require 'spec_helper'

describe Geo::JobArtifactRegistryFinder, :geo do
  include ::EE::GeoHelpers

  # Using let() instead of set() because set() does not work properly
  # when using the :delete DatabaseCleaner strategy, which is required for FDW
  # tests because a foreign table can't see changes inside a transaction of a
  # different connection.
  let(:secondary) { create(:geo_node) }
  let(:synced_group) { create(:group) }
  let(:synced_project) { create(:project, group: synced_group) }
  let(:unsynced_project) { create(:project) }

  let(:job_artifact_1) { create(:ci_job_artifact, project: synced_project) }
  let(:job_artifact_2) { create(:ci_job_artifact, project: unsynced_project) }
  let(:job_artifact_3) { create(:ci_job_artifact, project: synced_project) }
  let(:job_artifact_4) { create(:ci_job_artifact, project: unsynced_project) }
  let(:job_artifact_remote_1) { create(:ci_job_artifact, :remote_store, project: synced_project) }
  let(:job_artifact_remote_2) { create(:ci_job_artifact, :remote_store, project: unsynced_project) }

  subject { described_class.new(current_node: secondary) }

  before do
    stub_current_geo_node(secondary)
    stub_artifacts_object_storage
  end

  shared_examples 'counts all the things' do
    describe '#count_syncable' do
      before do
        job_artifact_1
        job_artifact_2
        job_artifact_3
        job_artifact_4
      end

      it 'counts job artifacts' do
        expect(subject.count_syncable).to eq 4
      end

      it 'ignores remote job artifacts' do
        job_artifact_1.update_column(:file_store, ObjectStorage::Store::REMOTE)

        expect(subject.count_syncable).to eq 3
      end

      it 'ignores expired job artifacts' do
        job_artifact_1.update_column(:expire_at, Date.yesterday)

        expect(subject.count_syncable).to eq 3
      end

      context 'with selective sync' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'counts job artifacts' do
          expect(subject.count_syncable).to eq 2
        end

        it 'ignores remote job artifacts' do
          job_artifact_1.update_column(:file_store, ObjectStorage::Store::REMOTE)

          expect(subject.count_syncable).to eq 1
        end

        it 'ignores expired job artifacts' do
          job_artifact_1.update_column(:expire_at, Date.yesterday)

          expect(subject.count_syncable).to eq 1
        end
      end
    end

    describe '#count_synced' do
      it 'delegates to #legacy_find_synced' do
        allow(subject).to receive(:aggregate_pushdown_supported?).and_return(false)

        expect(subject).to receive(:legacy_find_synced).and_call_original

        subject.count_synced
      end

      it 'delegates to #find_synced for PostgreSQL 10' do
        allow(subject).to receive(:aggregate_pushdown_supported?).and_return(true)

        expect(subject).to receive(:find_synced).and_call_original

        subject.count_synced
      end

      it 'counts job artifacts that have been synced' do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_2.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id)

        expect(subject.count_synced).to eq 2
      end

      it 'ignores remote job artifacts' do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_1.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_2.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id)

        expect(subject.count_synced).to eq 2
      end

      it 'ignores expired job artifacts' do
        job_artifact_1.update_column(:expire_at, Date.yesterday)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_2.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id)

        expect(subject.count_synced).to eq 2
      end

      context 'with selective sync' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'delegates to #legacy_find_synced' do
          expect(subject).to receive(:legacy_find_synced).and_call_original

          subject.count_synced
        end

        it 'counts job artifacts that has been synced' do
          create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, success: false)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_2.id)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id)

          expect(subject.count_synced).to eq 1
        end

        it 'ignores remote job artifacts' do
          create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_1.id)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_2.id)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id)

          expect(subject.count_synced).to eq 1
        end

        it 'ignores expired job artifacts' do
          job_artifact_1.update_column(:expire_at, Date.yesterday)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_2.id)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id)

          expect(subject.count_synced).to eq 1
        end
      end
    end

    describe '#count_failed' do
      it 'delegates to #legacy_find_failed' do
        allow(subject).to receive(:aggregate_pushdown_supported?).and_return(false)

        expect(subject).to receive(:legacy_find_failed).and_call_original

        subject.count_failed
      end

      it 'delegates to #find_failed' do
        allow(subject).to receive(:aggregate_pushdown_supported?).and_return(true)

        expect(subject).to receive(:find_failed).and_call_original

        subject.count_failed
      end

      it 'counts job artifacts that sync has failed' do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_2.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id, success: false)

        expect(subject.count_failed).to eq 2
      end

      it 'ignores remote job artifacts' do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_1.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_2.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id, success: false)

        expect(subject.count_failed).to eq 2
      end

      it 'ignores expired job artifacts' do
        job_artifact_1.update_column(:expire_at, Date.yesterday)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_2.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id, success: false)

        expect(subject.count_failed).to eq 2
      end

      context 'with selective sync' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'delegates to #legacy_find_failed' do
          expect(subject).to receive(:legacy_find_failed).and_call_original

          subject.count_failed
        end

        it 'counts job artifacts that sync has failed' do
          create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, success: false)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id)

          expect(subject.count_failed).to eq 1
        end

        it 'does not count job artifacts of unsynced projects' do
          create(:geo_job_artifact_registry, artifact_id: job_artifact_2.id, success: false)

          expect(subject.count_failed).to eq 0
        end

        it 'ignores remote job artifacts' do
          job_artifact_1.update_column(:file_store, ObjectStorage::Store::REMOTE)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, success: false)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_2.id, success: false)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id, success: false)

          expect(subject.count_failed).to eq 1
        end

        it 'ignores expired job artifacts' do
          job_artifact_1.update_column(:expire_at, Date.yesterday)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, success: false)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_2.id, success: false)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id, success: false)

          expect(subject.count_failed).to eq 1
        end
      end
    end

    describe '#count_synced_missing_on_primary' do
      it 'delegates to #legacy_find_synced_missing_on_primary' do
        allow(subject).to receive(:aggregate_pushdown_supported?).and_return(false)

        expect(subject).to receive(:legacy_find_synced_missing_on_primary).and_call_original

        subject.count_synced_missing_on_primary
      end

      it 'delegates to #find_synced_missing_on_primary for PostgreSQL 10' do
        allow(subject).to receive(:aggregate_pushdown_supported?).and_return(true)

        expect(subject).to receive(:find_synced_missing_on_primary).and_call_original

        subject.count_synced_missing_on_primary
      end

      it 'counts job artifacts that have been synced and are missing on the primary' do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, missing_on_primary: true)

        expect(subject.count_synced_missing_on_primary).to eq 1
      end

      it 'excludes job artifacts that are not missing on the primary' do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id)

        expect(subject.count_synced_missing_on_primary).to eq 0
      end

      it 'excludes job artifacts that are not synced' do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, success: false, missing_on_primary: true)

        expect(subject.count_synced_missing_on_primary).to eq 0
      end

      it 'ignores remote job artifacts' do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_1.id, missing_on_primary: true)

        expect(subject.count_synced_missing_on_primary).to eq 0
      end

      it 'ignores expired job artifacts' do
        job_artifact_1.update_column(:expire_at, Date.yesterday)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, missing_on_primary: true)

        expect(subject.count_synced_missing_on_primary).to eq 0
      end

      context 'with selective sync' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'delegates to #legacy_find_synced_missing_on_primary' do
          expect(subject).to receive(:legacy_find_synced_missing_on_primary).and_call_original

          subject.count_synced_missing_on_primary
        end

        it 'counts job artifacts that has been synced' do
          create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, missing_on_primary: true)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_2.id, missing_on_primary: true)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id, missing_on_primary: true)

          expect(subject.count_synced_missing_on_primary).to eq 2
        end

        it 'ignores remote job artifacts' do
          create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_1.id, missing_on_primary: true)

          expect(subject.count_synced_missing_on_primary).to eq 0
        end

        it 'ignores expired job artifacts' do
          job_artifact_1.update_column(:expire_at, Date.yesterday)
          create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, missing_on_primary: true)

          expect(subject.count_synced_missing_on_primary).to eq 0
        end
      end
    end
  end

  shared_examples 'finds all the things' do
    describe '#find_unsynced' do
      it 'delegates to the correct method' do
        expect(subject).to receive("#{method_prefix}_find_unsynced".to_sym).and_call_original

        subject.find_unsynced(batch_size: 10)
      end

      it 'returns job artifacts without an entry on the tracking database' do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, success: true)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id, success: false)

        job_artifacts = subject.find_unsynced(batch_size: 10)

        expect(job_artifacts).to match_ids(job_artifact_2, job_artifact_4)
      end

      it 'excludes job artifacts without an entry on the tracking database' do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id, success: true)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_3.id, success: false)

        job_artifacts = subject.find_unsynced(batch_size: 10, except_artifact_ids: [job_artifact_2.id])

        expect(job_artifacts).to match_ids(job_artifact_4)
      end

      it 'ignores remote job artifacts' do
        job_artifact_2.update_column(:file_store, ObjectStorage::Store::REMOTE)

        job_artifacts = subject.find_unsynced(batch_size: 10)

        expect(job_artifacts).to match_ids(job_artifact_4)
      end

      it 'ignores expired job artifacts' do
        job_artifact_2.update_column(:expire_at, Date.yesterday)

        job_artifacts = subject.find_unsynced(batch_size: 10)

        expect(job_artifacts).to match_ids(job_artifact_4)
      end
    end

    describe '#find_migrated_local' do
      it 'delegates to the correct method' do
        expect(subject).to receive("#{method_prefix}_find_migrated_local".to_sym).and_call_original

        subject.find_migrated_local(batch_size: 10)
      end

      it 'returns job artifacts remotely and successfully synced locally' do
        job_artifact = create(:ci_job_artifact, :remote_store, project: synced_project)
        create(:geo_job_artifact_registry, artifact_id: job_artifact.id)

        job_artifacts = subject.find_migrated_local(batch_size: 10)

        expect(job_artifacts).to match_ids(job_artifact)
      end

      it 'excludes job artifacts stored remotely, but not synced yet' do
        create(:ci_job_artifact, :remote_store, project: synced_project)

        job_artifacts = subject.find_migrated_local(batch_size: 10)

        expect(job_artifacts).to be_empty
      end

      it 'excludes synced job artifacts that are stored locally' do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_1.id)

        job_artifacts = subject.find_migrated_local(batch_size: 10)

        expect(job_artifacts).to be_empty
      end

      it 'excludes except_artifact_ids' do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_1.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_2.id)

        job_artifacts = subject.find_migrated_local(batch_size: 10, except_artifact_ids: [job_artifact_remote_1.id])

        expect(job_artifacts).to match_ids(job_artifact_remote_2)
      end

      it 'includes synced job artifacts that are expired' do
        job_artifact = create(:ci_job_artifact, :remote_store, project: synced_project, expire_at: Date.yesterday)
        create(:geo_job_artifact_registry, artifact_id: job_artifact.id)

        job_artifacts = subject.find_migrated_local(batch_size: 10)

        expect(job_artifacts).to match_ids(job_artifact)
      end
    end
  end

  it_behaves_like 'a file registry finder'
end
