require 'spec_helper'
require Rails.root.join('ee', 'db', 'migrate', '../../db/migrate/20180702114215_schedule_weight_system_note_comma_cleanup.rb')

describe ScheduleWeightSystemNoteCommaCleanup, :migration do
  describe '#up' do
    let(:notes) { table(:notes) }
    let(:system_note_metadata) { table(:system_note_metadata) }

    def create_system_note(id, note, metadata_action)
      notes.create!(id: id, note: note, system: true).tap do |system_note|
        system_note_metadata.create!(note_id: system_note.id, action: metadata_action)
      end
    end

    before do
      stub_const("#{described_class}::BATCH_SIZE", 1)

      # Should both be scheduled
      create_system_note(1, 'changed weight to 5,', 'weight')
      create_system_note(2, 'changed weight to 5,', 'weight')

      # Should not be scheduled - no trailing comma
      create_system_note(3, 'removed the weight', 'weight')

      # Should not be scheduled - not a weight note
      create_system_note(4, 'changed title from 5, to 5,', 'title')

      # Should not be scheduled - not a system note
      notes.create(id: 5, note: 'changed weight to 5,')
    end

    it 'schedules delayed background migrations in batches' do
      Sidekiq::Testing.fake! do
        Timecop.freeze do
          migrate!

          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(described_class::DELAY_INTERVAL, [1])
          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(described_class::DELAY_INTERVAL * 2, [2])
          expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        end
      end
    end
  end
end
