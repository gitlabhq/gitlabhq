# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::PruneOrphanedGeoEvents, :migration, :postgresql, schema: 20180626125654 do
  let(:event_table_name) { 'geo_repository_updated_events' }
  let(:geo_event_log) { table(:geo_event_log) }
  let(:geo_updated_events) { table(event_table_name) }
  let(:namespace) { table(:namespaces).create(name: 'foo', path: 'foo') }
  let(:project) { table(:projects).create(name: 'bar', path: 'path/to/bar', namespace_id: namespace.id) }

  subject(:background_migration) { described_class.new }

  describe 'PrunableEvent' do
    subject(:prunable_event) do
      Class.new(ActiveRecord::Base) do
        include Gitlab::BackgroundMigration::PruneOrphanedGeoEvents::PrunableEvent

        self.table_name = 'geo_repository_updated_events'
      end
    end

    describe '.geo_event_foreign_key' do
      it 'determines foreign key correctly' do
        expect(subject.geo_event_foreign_key).to eq('repository_updated_event_id')
      end
    end

    describe '.delete_batch_of_orphans!' do
      it 'vacuums table after deleting rows' do
        geo_updated_events.create!(project_id: project.id,
                                   source: 0,
                                   branches_affected: 0,
                                   tags_affected: 0)

        expect(subject).to receive(:vacuum!)

        subject.delete_batch_of_orphans!
      end
    end
  end

  describe '#perform' do
    before do
      geo_updated_events.create!(project_id: project.id,
                                 source: 0,
                                 branches_affected: 0,
                                 tags_affected: 0)
    end

    it 'takes the first table if no table is specified' do
      expect(subject).to receive(:prune_orphaned_rows).with(described_class::EVENT_TABLES.first).and_call_original

      subject.perform
    end

    it 'deletes orphans' do
      expect { background_migration.perform(event_table_name) }.to change { Geo::RepositoryUpdatedEvent.count }.by(-1)
    end

    it 'reschedules itself with the same table if positive number of rows were pruned' do
      allow(subject).to receive(:prune_orphaned_rows).and_return(5)
      expect(BackgroundMigrationWorker).to receive(:perform_in).with(5.minutes, described_class.name, event_table_name)

      subject.perform(event_table_name)
    end

    it 'reschedules itself with the next table if zero rows were pruned' do
      allow(subject).to receive(:prune_orphaned_rows).and_return(0)
      expect(BackgroundMigrationWorker).to receive(:perform_in).with(5.minutes, described_class.name, 'geo_repository_deleted_events')

      subject.perform(event_table_name)
    end
  end

  describe '#prune_orphaned_rows' do
    it 'returns the number of pruned rows' do
      event_model = spy(:event_model)
      allow(event_model).to receive(:delete_batch_of_orphans!).and_return(555)
      allow(subject).to receive(:event_model).and_return(event_model)

      expect(subject.prune_orphaned_rows(event_table_name)).to eq(555)
    end
  end

  describe '#next_table' do
    it 'takes the next table in the array' do
      expect(subject.next_table(described_class::EVENT_TABLES.first)).to eq(described_class::EVENT_TABLES.second)
    end

    it 'stops with the last table' do
      expect(subject.next_table(described_class::EVENT_TABLES.last)).to be_nil
    end

    it 'cycles for EVENT_TABLES.count' do
      table_name = 'geo_repository_created_events'
      count = 0

      loop do
        count += 1
        table_name = subject.next_table(table_name)
        break unless table_name
      end

      expect(count).to eq(described_class::EVENT_TABLES.count)
    end
  end
end
