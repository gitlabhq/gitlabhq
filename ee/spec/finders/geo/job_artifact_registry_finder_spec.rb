require 'spec_helper'

describe Geo::JobArtifactRegistryFinder, :geo do
  include ::EE::GeoHelpers

  let(:secondary) { create(:geo_node) }
  let(:synced_group) { create(:group) }
  let(:synced_project) { create(:project, group: synced_group) }
  let(:unsynced_project) { create(:project) }

  let!(:job_artifact_1) { create(:ci_job_artifact, id: 1, project: synced_project) }
  let!(:job_artifact_2) { create(:ci_job_artifact, id: 2, project: unsynced_project) }
  let!(:job_artifact_3) { create(:ci_job_artifact, id: 3, project: synced_project) }
  let!(:job_artifact_4) { create(:ci_job_artifact, id: 4, project: unsynced_project) }

  subject { described_class.new(current_node: secondary) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#count_synced_job_artifacts' do
    it 'delegates to #legacy_find_synced_job_artifacts' do
      allow(subject).to receive(:aggregate_pushdown_supported?).and_return(false)

      expect(subject).to receive(:legacy_find_synced_job_artifacts).and_call_original

      subject.count_synced_job_artifacts
    end

    it 'delegates to #find_synced_job_artifacts for PostgreSQL 10' do
      allow(subject).to receive(:aggregate_pushdown_supported?).and_return(true)

      expect(subject).to receive(:find_synced_job_artifacts).and_call_original

      subject.count_synced_job_artifacts
    end
  end

  describe '#count_failed_job_artifacts' do
    it 'delegates to #legacy_find_failed_job_artifacts' do
      allow(subject).to receive(:aggregate_pushdown_supported?).and_return(false)

      expect(subject).to receive(:legacy_find_failed_job_artifacts).and_call_original

      subject.count_failed_job_artifacts
    end

    it 'delegates to #find_failed_job_artifacts' do
      allow(subject).to receive(:aggregate_pushdown_supported?).and_return(true)

      expect(subject).to receive(:find_failed_job_artifacts).and_call_original

      subject.count_failed_job_artifacts
    end
  end

  shared_examples 'counts all the things' do
    describe '#count_job_artifacts' do
      it 'counts job artifacts' do
        expect(subject.count_job_artifacts).to eq 4
      end

      it 'ignores remote job artifacts' do
        job_artifact_1.update!(file_store: ObjectStorage::Store::REMOTE)

        expect(subject.count_job_artifacts).to eq 3
      end

      context 'with selective sync' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'counts job artifacts' do
          expect(subject.count_job_artifacts).to eq 2
        end

        it 'ignores remote job artifacts' do
          job_artifact_1.update!(file_store: ObjectStorage::Store::REMOTE)

          expect(subject.count_job_artifacts).to eq 1
        end
      end
    end

    describe '#count_synced_job_artifacts' do
      it 'counts job artifacts that have been synced' do
        create(:geo_file_registry, :job_artifact, file_id: job_artifact_1.id, success: false)
        create(:geo_file_registry, :job_artifact, file_id: job_artifact_2.id)
        create(:geo_file_registry, :job_artifact, file_id: job_artifact_3.id)

        expect(subject.count_synced_job_artifacts).to eq 2
      end

      it 'ignores remote job artifacts' do
        create(:geo_file_registry, :job_artifact, file_id: job_artifact_1.id)
        create(:geo_file_registry, :job_artifact, file_id: job_artifact_2.id)
        create(:geo_file_registry, :job_artifact, file_id: job_artifact_3.id)
        job_artifact_1.update!(file_store: ObjectStorage::Store::REMOTE)

        expect(subject.count_synced_job_artifacts).to eq 2
      end

      context 'with selective sync' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'delegates to #legacy_find_synced_job_artifacts' do
          expect(subject).to receive(:legacy_find_synced_job_artifacts).and_call_original

          subject.count_synced_job_artifacts
        end

        it 'counts job artifacts that has been synced' do
          create(:geo_file_registry, :job_artifact, file_id: job_artifact_1.id, success: false)
          create(:geo_file_registry, :job_artifact, file_id: job_artifact_2.id)
          create(:geo_file_registry, :job_artifact, file_id: job_artifact_3.id)

          expect(subject.count_synced_job_artifacts).to eq 1
        end

        it 'ignores remote job artifacts' do
          create(:geo_file_registry, :job_artifact, file_id: job_artifact_1.id)
          create(:geo_file_registry, :job_artifact, file_id: job_artifact_2.id)
          create(:geo_file_registry, :job_artifact, file_id: job_artifact_3.id)
          job_artifact_1.update!(file_store: ObjectStorage::Store::REMOTE)

          expect(subject.count_synced_job_artifacts).to eq 1
        end
      end
    end

    describe '#count_failed_job_artifacts' do
      it 'counts job artifacts that sync has failed' do
        create(:geo_file_registry, :job_artifact, file_id: job_artifact_1.id, success: false)
        create(:geo_file_registry, :job_artifact, file_id: job_artifact_2.id)
        create(:geo_file_registry, :job_artifact, file_id: job_artifact_3.id, success: false)

        expect(subject.count_failed_job_artifacts).to eq 2
      end

      it 'ignores remote job artifacts' do
        create(:geo_file_registry, :job_artifact, file_id: job_artifact_1.id, success: false)
        create(:geo_file_registry, :job_artifact, file_id: job_artifact_2.id, success: false)
        create(:geo_file_registry, :job_artifact, file_id: job_artifact_3.id, success: false)
        job_artifact_1.update!(file_store: ObjectStorage::Store::REMOTE)

        expect(subject.count_failed_job_artifacts).to eq 2
      end

      context 'with selective sync' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'delegates to #legacy_find_failed_job_artifacts' do
          expect(subject).to receive(:legacy_find_failed_job_artifacts).and_call_original

          subject.count_failed_job_artifacts
        end

        it 'counts job artifacts that sync has failed' do
          create(:geo_file_registry, :job_artifact, file_id: job_artifact_1.id, success: false)
          create(:geo_file_registry, :job_artifact, file_id: job_artifact_3.id)

          expect(subject.count_failed_job_artifacts).to eq 1
        end

        it 'does not count job artifacts of unsynced projects' do
          create(:geo_file_registry, :job_artifact, file_id: job_artifact_2.id, success: false)

          expect(subject.count_failed_job_artifacts).to eq 0
        end

        it 'ignores remote job artifacts' do
          create(:geo_file_registry, :job_artifact, file_id: job_artifact_1.id, success: false)
          create(:geo_file_registry, :job_artifact, file_id: job_artifact_2.id, success: false)
          create(:geo_file_registry, :job_artifact, file_id: job_artifact_3.id, success: false)
          job_artifact_1.update!(file_store: ObjectStorage::Store::REMOTE)

          expect(subject.count_failed_job_artifacts).to eq 1
        end
      end
    end
  end

  shared_examples 'finds all the things' do
    describe '#find_unsynced_job_artifacts' do
      it 'delegates to the correct method' do
        expect(subject).to receive("#{method_prefix}_find_unsynced_job_artifacts".to_sym).and_call_original

        subject.find_unsynced_job_artifacts(batch_size: 10)
      end

      it 'returns job artifacts without an entry on the tracking database' do
        create(:geo_file_registry, :job_artifact, file_id: job_artifact_1.id, success: true)
        create(:geo_file_registry, :job_artifact, file_id: job_artifact_3.id, success: false)

        job_artifacts = subject.find_unsynced_job_artifacts(batch_size: 10)

        expect(job_artifacts).to match_ids(job_artifact_2, job_artifact_4)
      end

      it 'excludes job artifacts without an entry on the tracking database' do
        create(:geo_file_registry, :job_artifact, file_id: job_artifact_1.id, success: true)
        create(:geo_file_registry, :job_artifact, file_id: job_artifact_3.id, success: false)

        job_artifacts = subject.find_unsynced_job_artifacts(batch_size: 10, except_file_ids: [job_artifact_2.id])

        expect(job_artifacts).to match_ids(job_artifact_4)
      end
    end
  end

  # Disable transactions via :delete method because a foreign table
  # can't see changes inside a transaction of a different connection.
  context 'FDW', :delete do
    before do
      skip('FDW is not configured') if Gitlab::Database.postgresql? && !Gitlab::Geo::Fdw.enabled?
    end

    include_examples 'counts all the things'

    include_examples 'finds all the things' do
      let(:method_prefix) { 'fdw' }
    end
  end

  context 'Legacy' do
    before do
      allow(Gitlab::Geo::Fdw).to receive(:enabled?).and_return(false)
    end

    include_examples 'counts all the things'

    include_examples 'finds all the things' do
      let(:method_prefix) { 'legacy' }
    end
  end
end
