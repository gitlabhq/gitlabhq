require 'spec_helper'

describe GeoNodeStatus, :geo do
  include ::EE::GeoHelpers

  let!(:primary)  { create(:geo_node, :primary) }
  let!(:secondary) { create(:geo_node) }

  let!(:group)     { create(:group) }
  let!(:project_1) { create(:project, group: group) }
  let!(:project_2) { create(:project, group: group) }
  let!(:project_3) { create(:project) }
  let!(:project_4) { create(:project) }

  subject(:status) { described_class.current_node_status }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#healthy?' do
    context 'when health is blank' do
      it 'returns true' do
        subject.status_message = ''

        expect(subject.healthy?).to be true
      end
    end

    context 'when health is present' do
      it 'returns true' do
        subject.status_message = 'Healthy'

        expect(subject.healthy?).to be true
      end

      it 'returns false' do
        subject.status_message = 'something went wrong'

        expect(subject.healthy?).to be false
      end
    end
  end

  describe '#status_message' do
    it 'delegates to the HealthCheck' do
      expect(HealthCheck::Utils).to receive(:process_checks).with(['geo']).once

      subject
    end
  end

  # Disable transactions via :delete method because a foreign table
  # can't see changes inside a transaction of a different connection.
  describe '#attachments_synced_count', :delete do
    it 'only counts successful syncs' do
      create_list(:user, 3, avatar: fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png'))
      uploads = Upload.all.pluck(:id)

      create(:geo_file_registry, :avatar, file_id: uploads[0])
      create(:geo_file_registry, :avatar, file_id: uploads[1])
      create(:geo_file_registry, :avatar, file_id: uploads[2], success: false)

      expect(subject.attachments_synced_count).to eq(2)
    end

    it 'does not count synced files that were replaced' do
      user = create(:user, avatar: fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png'))

      expect(subject.attachments_count).to eq(1)
      expect(subject.attachments_synced_count).to eq(0)

      upload = Upload.find_by(model: user, uploader: 'AvatarUploader')
      create(:geo_file_registry, :avatar, file_id: upload.id)

      subject = described_class.current_node_status

      expect(subject.attachments_count).to eq(1)
      expect(subject.attachments_synced_count).to eq(1)

      user.update(avatar: fixture_file_upload(Rails.root + 'spec/fixtures/rails_sample.jpg', 'image/jpg'))

      subject = described_class.current_node_status

      expect(subject.attachments_count).to eq(1)
      expect(subject.attachments_synced_count).to eq(0)

      upload = Upload.find_by(model: user, uploader: 'AvatarUploader')
      create(:geo_file_registry, :avatar, file_id: upload.id)

      subject = described_class.current_node_status

      expect(subject.attachments_count).to eq(1)
      expect(subject.attachments_synced_count).to eq(1)
    end
  end

  # Disable transactions via :delete method because a foreign table
  # can't see changes inside a transaction of a different connection.
  describe '#attachments_synced_missing_on_primary_count', :delete do
    it 'only counts successful syncs' do
      create_list(:user, 3, avatar: fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png'))
      uploads = Upload.all.pluck(:id)

      create(:geo_file_registry, :avatar, file_id: uploads[0], missing_on_primary: true)
      create(:geo_file_registry, :avatar, file_id: uploads[1])
      create(:geo_file_registry, :avatar, file_id: uploads[2], success: false)

      expect(subject.attachments_synced_missing_on_primary_count).to eq(1)
    end
  end

  describe '#attachments_failed_count', :delete do
    it 'counts failed avatars, attachment, personal snippets and files' do
      # These two should be ignored
      create(:geo_file_registry, :lfs, :with_file, success: false)
      create(:geo_file_registry, :with_file)

      create(:geo_file_registry, :with_file, file_type: :personal_file, success: false)
      create(:geo_file_registry, :with_file, file_type: :attachment, success: false)
      create(:geo_file_registry, :avatar, :with_file, success: false)
      create(:geo_file_registry, :with_file, success: false)

      expect(subject.attachments_failed_count).to eq(4)
    end
  end

  describe '#attachments_synced_in_percentage', :delete do
    let(:avatar) { fixture_file_upload(Rails.root.join('spec/fixtures/dk.png')) }
    let(:upload_1) { create(:upload, model: group, path: avatar) }
    let(:upload_2) { create(:upload, model: project_1, path: avatar) }

    before do
      create(:upload, model: create(:group), path: avatar)
      create(:upload, model: project_3, path: avatar)
    end

    it 'returns 0 when no objects are available' do
      expect(subject.attachments_synced_in_percentage).to eq(0)
    end

    it 'returns the right percentage with no group restrictions' do
      create(:geo_file_registry, :avatar, file_id: upload_1.id)
      create(:geo_file_registry, :avatar, file_id: upload_2.id)

      expect(subject.attachments_synced_in_percentage).to be_within(0.0001).of(50)
    end

    it 'returns the right percentage with group restrictions' do
      secondary.update!(selective_sync_type: 'namespaces', namespaces: [group])
      create(:geo_file_registry, :avatar, file_id: upload_1.id)
      create(:geo_file_registry, :avatar, file_id: upload_2.id)

      expect(subject.attachments_synced_in_percentage).to be_within(0.0001).of(100)
    end
  end

  describe '#db_replication_lag_seconds' do
    it 'returns the set replication lag if secondary' do
      allow(Gitlab::Geo).to receive(:secondary?).and_return(true)
      allow(Gitlab::Geo::HealthCheck).to receive(:db_replication_lag_seconds).and_return(1000)

      expect(subject.db_replication_lag_seconds).to eq(1000)
    end

    it "doesn't attempt to set replication lag if primary" do
      stub_current_geo_node(primary)
      expect(Gitlab::Geo::HealthCheck).not_to receive(:db_replication_lag_seconds)

      expect(subject.db_replication_lag_seconds).to eq(nil)
    end
  end

  # Disable transactions via :delete method because a foreign table
  # can't see changes inside a transaction of a different connection.
  describe '#lfs_objects_synced_count', :delete do
    it 'counts synced LFS objects' do
      # These four should be ignored
      create(:geo_file_registry, success: false)
      create(:geo_file_registry, :avatar)
      create(:geo_file_registry, file_type: :attachment)
      create(:geo_file_registry, :lfs, :with_file, success: false)

      create(:geo_file_registry, :lfs, :with_file, success: true)

      expect(subject.lfs_objects_synced_count).to eq(1)
    end
  end

  # Disable transactions via :delete method because a foreign table
  # can't see changes inside a transaction of a different connection.
  describe '#lfs_objects_synced_missing_on_primary_count', :delete do
    it 'counts LFS objects marked as synced due to file missing on the primary' do
      # These four should be ignored
      create(:geo_file_registry, success: false)
      create(:geo_file_registry, :avatar, missing_on_primary: true)
      create(:geo_file_registry, file_type: :attachment, missing_on_primary: true)
      create(:geo_file_registry, :lfs, :with_file, success: false)

      create(:geo_file_registry, :lfs, :with_file, success: true, missing_on_primary: true)

      expect(subject.lfs_objects_synced_missing_on_primary_count).to eq(1)
    end
  end

  # Disable transactions via :delete method because a foreign table
  # can't see changes inside a transaction of a different connection.
  describe '#lfs_objects_failed_count', :delete do
    it 'counts failed LFS objects' do
      # These four should be ignored
      create(:geo_file_registry, success: false)
      create(:geo_file_registry, :avatar, success: false)
      create(:geo_file_registry, file_type: :attachment, success: false)
      create(:geo_file_registry, :lfs, :with_file)

      create(:geo_file_registry, :lfs, :with_file, success: false)

      expect(subject.lfs_objects_failed_count).to eq(1)
    end
  end

  # Disable transactions via :delete method because a foreign table
  # can't see changes inside a transaction of a different connection.
  describe '#lfs_objects_synced_in_percentage', :delete do
    let(:lfs_object_project) { create(:lfs_objects_project, project: project_1) }

    before do
      allow(ProjectCacheWorker).to receive(:perform_async).and_return(true)

      create(:lfs_objects_project, project: project_1)
      create_list(:lfs_objects_project, 2, project: project_3)
    end

    it 'returns 0 when no objects are available' do
      expect(subject.lfs_objects_synced_in_percentage).to eq(0)
    end

    it 'returns the right percentage with no group restrictions' do
      create(:geo_file_registry, :lfs, file_id: lfs_object_project.lfs_object_id, success: true)

      expect(subject.lfs_objects_synced_in_percentage).to be_within(0.0001).of(25)
    end

    it 'returns the right percentage with group restrictions' do
      secondary.update!(selective_sync_type: 'namespaces', namespaces: [group])
      create(:geo_file_registry, :lfs, file_id: lfs_object_project.lfs_object_id, success: true)

      expect(subject.lfs_objects_synced_in_percentage).to be_within(0.0001).of(50)
    end
  end

  # Disable transactions via :delete method because a foreign table
  # can't see changes inside a transaction of a different connection.
  describe '#job_artifacts_synced_count', :delete do
    it 'counts synced job artifacts' do
      # These should be ignored
      create(:geo_file_registry, success: true)
      create(:geo_job_artifact_registry, :with_artifact, success: false)

      create(:geo_job_artifact_registry, :with_artifact, success: true)

      expect(subject.job_artifacts_synced_count).to eq(1)
    end
  end

  # Disable transactions via :delete method because a foreign table
  # can't see changes inside a transaction of a different connection.
  describe '#job_artifacts_synced_missing_on_primary_count', :delete do
    it 'counts job artifacts marked as synced due to file missing on the primary' do
      # These should be ignored
      create(:geo_file_registry, success: true, missing_on_primary: true)
      create(:geo_job_artifact_registry, :with_artifact, success: true)

      create(:geo_job_artifact_registry, :with_artifact, success: true, missing_on_primary: true)

      expect(subject.job_artifacts_synced_missing_on_primary_count).to eq(1)
    end
  end

  # Disable transactions via :delete method because a foreign table
  # can't see changes inside a transaction of a different connection.
  describe '#job_artifacts_failed_count', :delete do
    it 'counts failed job artifacts' do
      # These should be ignored
      create(:geo_file_registry, success: false)
      create(:geo_file_registry, :avatar, success: false)
      create(:geo_file_registry, file_type: :attachment, success: false)
      create(:geo_job_artifact_registry, :with_artifact, success: true)

      create(:geo_job_artifact_registry, :with_artifact, success: false)

      expect(subject.job_artifacts_failed_count).to eq(1)
    end
  end

  # Disable transactions via :delete method because a foreign table
  # can't see changes inside a transaction of a different connection.
  describe '#job_artifacts_synced_in_percentage', :delete do
    context 'when artifacts are available' do
      before do
        [project_1, project_2, project_3, project_4].each_with_index do |project, index|
          build = create(:ci_build, project: project)
          job_artifact = create(:ci_job_artifact, job: build)

          create(:geo_job_artifact_registry, success: index.even?, artifact_id: job_artifact.id)
        end
      end

      it 'returns the right percentage with no group restrictions' do
        expect(subject.job_artifacts_synced_in_percentage).to be_within(0.0001).of(50)
      end

      it 'returns the right percentage with group restrictions' do
        secondary.update_attribute(:namespaces, [group])

        expect(subject.job_artifacts_synced_in_percentage).to be_within(0.0001).of(50)
      end
    end

    it 'returns 0 when no artifacts are available' do
      expect(subject.job_artifacts_synced_in_percentage).to eq(0)
    end
  end

  describe '#repositories_failed_count' do
    before do
      create(:geo_project_registry, :sync_failed, project: project_1)
      create(:geo_project_registry, :sync_failed, project: project_3)
      create(:geo_project_registry, :repository_syncing, project: project_4)
      create(:geo_project_registry, :wiki_syncing)
    end

    it 'returns the right number of failed repos with no group restrictions' do
      expect(subject.repositories_failed_count).to eq(2)
    end

    it 'returns the right number of failed repos with group restrictions' do
      secondary.update!(selective_sync_type: 'namespaces', namespaces: [group])

      expect(subject.repositories_failed_count).to eq(1)
    end
  end

  describe '#wikis_failed_count' do
    before do
      create(:geo_project_registry, :sync_failed, project: project_1)
      create(:geo_project_registry, :sync_failed, project: project_3)
      create(:geo_project_registry, :repository_syncing, project: project_4)
      create(:geo_project_registry, :wiki_syncing)
    end

    it 'returns the right number of failed repos with no group restrictions' do
      expect(subject.wikis_failed_count).to eq(2)
    end

    it 'returns the right number of failed repos with group restrictions' do
      secondary.update!(selective_sync_type: 'namespaces', namespaces: [group])

      expect(subject.wikis_failed_count).to eq(1)
    end
  end

  describe '#repositories_synced_in_percentage' do
    it 'returns 0 when no projects are available' do
      expect(subject.repositories_synced_in_percentage).to eq(0)
    end

    it 'returns 0 when project count is unknown' do
      allow(subject).to receive(:repositories_count).and_return(nil)

      expect(subject.repositories_synced_in_percentage).to eq(0)
    end

    it 'returns the right percentage with no group restrictions' do
      create(:geo_project_registry, :synced, project: project_1)

      expect(subject.repositories_synced_in_percentage).to be_within(0.0001).of(25)
    end

    it 'returns the right percentage with group restrictions' do
      secondary.update!(selective_sync_type: 'namespaces', namespaces: [group])
      create(:geo_project_registry, :synced, project: project_1)

      expect(subject.repositories_synced_in_percentage).to be_within(0.0001).of(50)
    end
  end

  # Disable transactions via :delete method because a foreign table
  # can't see changes inside a transaction of a different connection.
  describe '#wikis_synced_in_percentage', :delete do
    it 'returns 0 when no projects are available' do
      expect(subject.wikis_synced_in_percentage).to eq(0)
    end

    it 'returns 0 when project count is unknown' do
      allow(subject).to receive(:wikis_count).and_return(nil)

      expect(subject.wikis_synced_in_percentage).to eq(0)
    end

    it 'returns the right percentage with no group restrictions' do
      create(:geo_project_registry, :synced, project: project_1)

      expect(subject.wikis_synced_in_percentage).to be_within(0.0001).of(25)
    end

    it 'returns the right percentage with group restrictions' do
      secondary.update!(selective_sync_type: 'namespaces', namespaces: [group])
      create(:geo_project_registry, :synced, project: project_1)

      expect(subject.wikis_synced_in_percentage).to be_within(0.0001).of(50)
    end
  end

  describe '#replication_slots_used_count' do
    it 'returns the right number of used replication slots' do
      stub_current_geo_node(primary)
      allow(primary).to receive(:replication_slots_used_count).and_return(1)

      expect(subject.replication_slots_used_count).to eq(1)
    end
  end

  describe '#replication_slots_used_in_percentage' do
    it 'returns 0 when no replication slots are available' do
      expect(subject.replication_slots_used_in_percentage).to eq(0)
    end

    it 'returns 0 when replication slot count is unknown' do
      allow(subject).to receive(:replication_slot_count).and_return(nil)

      expect(subject.replication_slots_used_in_percentage).to eq(0)
    end

    it 'returns the right percentage' do
      stub_current_geo_node(primary)
      allow(subject).to receive(:replication_slots_count).and_return(2)
      allow(subject).to receive(:replication_slots_used_count).and_return(1)

      expect(subject.replication_slots_used_in_percentage).to be_within(0.0001).of(50)
    end
  end

  describe '#replication_slots_max_retained_wal_bytes' do
    it 'returns the number of bytes replication slots are using' do
      stub_current_geo_node(primary)
      allow(primary).to receive(:replication_slots_max_retained_wal_bytes).and_return(2.megabytes)

      expect(subject.replication_slots_max_retained_wal_bytes).to eq(2.megabytes)
    end

    it 'handles large values' do
      stub_current_geo_node(primary)
      allow(primary).to receive(:replication_slots_max_retained_wal_bytes).and_return(900.gigabytes)

      expect(subject.replication_slots_max_retained_wal_bytes).to eq(900.gigabytes)
    end
  end

  describe '#repositories_verified_count' do
    context 'on the primary' do
      before do
        stub_current_geo_node(primary)
      end

      it 'returns the right number of verified repositories' do
        stub_feature_flags(geo_repository_verification: true)
        create(:repository_state, :repository_verified)
        create(:repository_state, :repository_verified)

        expect(subject.repositories_verified_count).to eq(2)
      end

      it 'returns existing value when feature flag if off' do
        stub_feature_flags(geo_repository_verification: false)
        create(:geo_node_status, :healthy, geo_node: primary)

        expect(subject.repositories_verified_count).to eq(501)
      end
    end

    context 'on the secondary' do
      before do
        stub_current_geo_node(secondary)
      end

      it 'returns the right number of verified repositories' do
        stub_feature_flags(geo_repository_verification: true)
        create(:geo_project_registry, :repository_verified)
        create(:geo_project_registry, :repository_verified)

        expect(subject.repositories_verified_count).to eq(2)
      end

      it 'returns existing value when feature flag if off' do
        stub_feature_flags(geo_repository_verification: false)
        create(:geo_node_status, :healthy, geo_node: secondary)

        expect(subject.repositories_verified_count).to eq(501)
      end
    end
  end

  describe '#repositories_verification_failed_count' do
    context 'on the primary' do
      before do
        stub_current_geo_node(primary)
      end

      it 'returns the right number of failed repositories' do
        stub_feature_flags(geo_repository_verification: true)
        create(:repository_state, :repository_failed)
        create(:repository_state, :repository_failed)

        expect(subject.repositories_verification_failed_count).to eq(2)
      end

      it 'returns existing value when feature flag if off' do
        stub_feature_flags(geo_repository_verification: false)
        create(:geo_node_status, :healthy, geo_node: primary)

        expect(subject.repositories_verification_failed_count).to eq(100)
      end
    end

    context 'on the secondary' do
      before do
        stub_current_geo_node(secondary)
      end

      it 'returns the right number of failed repositories' do
        stub_feature_flags(geo_repository_verification: true)
        create(:geo_project_registry, :repository_verification_failed)
        create(:geo_project_registry, :repository_verification_failed)

        expect(subject.repositories_verification_failed_count).to eq(2)
      end

      it 'returns existing value when feature flag if off' do
        stub_feature_flags(geo_repository_verification: false)
        create(:geo_node_status, :healthy, geo_node: secondary)

        expect(subject.repositories_verification_failed_count).to eq(100)
      end
    end
  end

  describe '#wikis_verified_count' do
    context 'on the primary' do
      before do
        stub_current_geo_node(primary)
      end

      it 'returns the right number of verified wikis' do
        stub_feature_flags(geo_repository_verification: true)
        create(:repository_state, :wiki_verified)
        create(:repository_state, :wiki_verified)

        expect(subject.wikis_verified_count).to eq(2)
      end

      it 'returns existing value when feature flag if off' do
        stub_feature_flags(geo_repository_verification: false)
        create(:geo_node_status, :healthy, geo_node: primary)

        expect(subject.wikis_verified_count).to eq(499)
      end
    end

    context 'on the secondary' do
      before do
        stub_current_geo_node(secondary)
      end

      it 'returns the right number of verified wikis' do
        stub_feature_flags(geo_repository_verification: true)
        create(:geo_project_registry, :wiki_verified)
        create(:geo_project_registry, :wiki_verified)

        expect(subject.wikis_verified_count).to eq(2)
      end

      it 'returns existing value when feature flag if off' do
        stub_feature_flags(geo_repository_verification: false)
        create(:geo_node_status, :healthy, geo_node: secondary)

        expect(subject.wikis_verified_count).to eq(499)
      end
    end
  end

  describe '#wikis_verification_failed_count' do
    context 'on the primary' do
      before do
        stub_current_geo_node(primary)
      end

      it 'returns the right number of failed wikis' do
        stub_feature_flags(geo_repository_verification: true)
        create(:repository_state, :wiki_failed)
        create(:repository_state, :wiki_failed)

        expect(subject.wikis_verification_failed_count).to eq(2)
      end

      it 'returns existing value when feature flag if off' do
        stub_feature_flags(geo_repository_verification: false)
        create(:geo_node_status, :healthy, geo_node: primary)

        expect(subject.wikis_verification_failed_count).to eq(99)
      end
    end

    context 'on the secondary' do
      before do
        stub_current_geo_node(secondary)
      end

      it 'returns the right number of failed wikis' do
        stub_feature_flags(geo_repository_verification: true)
        create(:geo_project_registry, :wiki_verification_failed)
        create(:geo_project_registry, :wiki_verification_failed)

        expect(subject.wikis_verification_failed_count).to eq(2)
      end

      it 'returns existing value when feature flag if off' do
        stub_feature_flags(geo_repository_verification: false)
        create(:geo_node_status, :healthy, geo_node: secondary)

        expect(subject.wikis_verification_failed_count).to eq(99)
      end
    end
  end

  describe '#last_event_id and #last_event_date' do
    it 'returns nil when no events are available' do
      expect(subject.last_event_id).to be_nil
      expect(subject.last_event_date).to be_nil
    end

    it 'returns the latest event' do
      created_at = Date.today.to_time(:utc)
      event = create(:geo_event_log, created_at: created_at)

      expect(subject.last_event_id).to eq(event.id)
      expect(subject.last_event_date).to eq(created_at)
    end
  end

  describe '#cursor_last_event_id and #cursor_last_event_date' do
    it 'returns nil when no events are available' do
      expect(subject.cursor_last_event_id).to be_nil
      expect(subject.cursor_last_event_date).to be_nil
    end

    it 'returns the latest event ID if secondary' do
      allow(Gitlab::Geo).to receive(:secondary?).and_return(true)
      event = create(:geo_event_log_state)

      expect(subject.cursor_last_event_id).to eq(event.event_id)
    end

    it "doesn't attempt to retrieve cursor if primary" do
      stub_current_geo_node(primary)
      create(:geo_event_log_state)

      expect(subject.cursor_last_event_date).to eq(nil)
      expect(subject.cursor_last_event_id).to eq(nil)
    end
  end

  describe '#version' do
    it { expect(status.version).to eq(Gitlab::VERSION) }
  end

  describe '#revision' do
    it {  expect(status.revision).to eq(Gitlab::REVISION) }
  end

  describe '#[]' do
    it 'returns values for each attribute' do
      expect(subject[:repositories_count]).to eq(4)
      expect(subject[:repositories_synced_count]).to eq(0)
    end

    it 'raises an error for invalid attributes' do
      expect { subject[:testme] }.to raise_error(NoMethodError)
    end
  end

  shared_examples 'timestamp parameters' do |timestamp_column, date_column|
    it 'returns the value it was assigned via UNIX timestamp' do
      now = Time.now.beginning_of_day.utc
      subject.update_attribute(timestamp_column, now.to_i)

      expect(subject.public_send(date_column)).to eq(now)
      expect(subject.public_send(timestamp_column)).to eq(now.to_i)
    end
  end

  describe '#last_successful_status_check_timestamp' do
    it_behaves_like 'timestamp parameters', :last_successful_status_check_timestamp, :last_successful_status_check_at
  end

  describe '#last_event_timestamp' do
    it_behaves_like 'timestamp parameters', :last_event_timestamp, :last_event_date
  end

  describe '#cursor_last_event_timestamp' do
    it_behaves_like 'timestamp parameters', :cursor_last_event_timestamp, :cursor_last_event_date
  end

  describe '#storage_shards' do
    it "returns the current node's shard config" do
      expect(subject[:storage_shards].as_json).to eq(StorageShard.all.as_json)
    end
  end

  describe '#from_json' do
    it 'returns a new GeoNodeStatus excluding parameters' do
      status = create(:geo_node_status)

      data = GeoNodeStatusSerializer.new.represent(status).as_json
      data['id'] = 10000

      result = described_class.from_json(data)

      expect(result.id).to be_nil
      expect(result.attachments_count).to eq(status.attachments_count)
      expect(result.cursor_last_event_date).to eq(Time.at(status.cursor_last_event_timestamp))
      expect(result.storage_shards.count).to eq(Settings.repositories.storages.count)
    end
  end

  describe '#storage_shards_match?' do
    before do
      stub_primary_node
    end

    set(:status) { create(:geo_node_status) }
    let(:data) { GeoNodeStatusSerializer.new.represent(status).as_json }
    let(:result) { described_class.from_json(data) }

    it 'returns nil if no shard data is available' do
      data.delete('storage_shards')

      expect(result.storage_shards_match?).to be nil
    end

    it 'returns false if the storage shards do not match' do
      data['storage_shards'].first['name'] = 'broken-shard'

      expect(result.storage_shards_match?).to be false
    end

    it 'returns true if the storage shards match in different order' do
      status.storage_shards.shuffle!

      expect(result.storage_shards_match?).to be true
    end

    context 'in development mode' do
      before do
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      it 'returns true if keys are same but paths are different' do
        data['storage_shards'].first['path'] = '/tmp/different-path'

        expect(result.storage_shards_match?).to be_truthy
      end
    end
  end
end
