require 'spec_helper'

describe Gitlab::BackgroundMigration::RemoveCommaFromWeightSystemNotes, :migration, schema: 20180702114215 do
  RSpec::Matchers.define_negated_matcher :not_change, :change

  describe '#perform' do
    let(:notes) { table(:notes) }
    let(:system_note_metadata) { table(:system_note_metadata) }

    def create_system_note(note, metadata_action)
      notes.create(note: note, note_html: note, system: true).tap do |system_note|
        system_note_metadata.create(note_id: system_note.id, action: metadata_action)
      end
    end

    it 'processes all notes in the batch' do
      weight_note_1 = create_system_note('changed weight to 1,', 'weight')
      weight_note_2 = create_system_note('changed weight to 2,', 'weight')
      weight_note_3 = create_system_note('changed weight to 3,', 'weight')

      expect { subject.perform([weight_note_1.id, weight_note_2.id]) }
        .to change { weight_note_1.reload.note }
        .and change { weight_note_1.reload.note_html }
        .and change { weight_note_2.reload.note }
        .and change { weight_note_2.reload.note_html }
        .and not_change { weight_note_3.reload.note }
        .and not_change { weight_note_3.reload.note_html }
    end
  end
end
