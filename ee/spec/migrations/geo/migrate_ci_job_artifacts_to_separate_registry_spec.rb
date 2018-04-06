require 'spec_helper'
require Rails.root.join('ee', 'db', 'geo', 'migrate', '20180322062741_migrate_ci_job_artifacts_to_separate_registry.rb')

describe MigrateCiJobArtifactsToSeparateRegistry, :geo, :migration do
  let(:file_registry) { table(:file_registry) }
  let(:job_artifact_registry) { table(:job_artifact_registry) }

  before do
    file_registry.create!(file_id: 1, file_type: 'job_artifact', success: true, bytes: 1024, sha256: '0' * 64)
    file_registry.create!(file_id: 2, file_type: 'job_artifact', success: false, bytes: 2048, sha256: '1' * 64)
    file_registry.create!(file_id: 3, file_type: 'attachment', success: true)
    file_registry.create!(file_id: 4, file_type: 'job_artifact', success: false, bytes: 4096, sha256: '2' * 64)
  end

  describe '#up' do
    it 'migrates all job artifacts to its own data table' do
      expect(file_registry.all.count).to eq(4)

      migrate!

      expect(file_registry.all.count).to eq(4)
      expect(job_artifact_registry.all.count).to eq(3)

      expect(job_artifact_registry.where(artifact_id: 1, success: true, bytes: 1024, sha256: '0' * 64).count).to eq(1)
      expect(job_artifact_registry.where(artifact_id: 2, success: false, bytes: 2048, sha256: '1' * 64).count).to eq(1)
      expect(job_artifact_registry.where(artifact_id: 4, success: false, bytes: 4096, sha256: '2' * 64).count).to eq(1)
      expect(file_registry.where(file_id: 3, file_type: 'attachment', success: true).count).to eq(1)
    end

    it 'creates a new artifact with the trigger' do
      migrate!

      expect(job_artifact_registry.all.count).to eq(3)

      file_registry.create!(file_id: 5, file_type: 'job_artifact', success: true, bytes: 8192, sha256: '3' * 64)

      expect(job_artifact_registry.all.count).to eq(4)
      expect(job_artifact_registry.where(artifact_id: 5, success: true, bytes: 8192, sha256: '3' * 64).count).to eq(1)
    end

    it 'updates a new artifact with the trigger' do
      migrate!

      expect(job_artifact_registry.all.count).to eq(3)

      entry = file_registry.find_by(file_id: 1)
      entry.update_attributes(success: false, bytes: 10240, sha256: '10' * 64)

      expect(job_artifact_registry.where(artifact_id: 1, success: false, bytes: 10240, sha256: '10' * 64).count).to eq(1)
    end

    it 'creates a new artifact using the next ID' do
      migrate!

      max_id = job_artifact_registry.maximum(:id)
      last_id = job_artifact_registry.create!(artifact_id: 5, success: true).id

      expect(last_id - max_id).to eq(1)
    end
  end

  describe '#down' do
    it 'rolls back data properly' do
      migrate!

      expect(file_registry.all.count).to eq(4)
      expect(job_artifact_registry.all.count).to eq(3)

      schema_migrate_down!

      expect(file_registry.all.count).to eq(4)
      expect(file_registry.where(file_type: 'attachment').count).to eq(1)
      expect(file_registry.where(file_type: 'job_artifact').count).to eq(3)

      expect(file_registry.where(file_type: 'job_artifact', bytes: 1024, sha256: '0' * 64).count).to eq(1)
      expect(file_registry.where(file_type: 'job_artifact', bytes: 2048, sha256: '1' * 64).count).to eq(1)
      expect(file_registry.where(file_type: 'job_artifact', bytes: 4096, sha256: '2' * 64).count).to eq(1)
    end
  end
end
