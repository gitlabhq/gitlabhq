require 'spec_helper'
require Rails.root.join('ee', 'db', 'migrate', '../../db/migrate/20180530201303_remove_commas_from_weight_note.rb')

describe RemoveCommasFromWeightNote, :migration do
  RSpec::Matchers.define_negated_matcher :not_change, :change

  describe '#up' do
    let(:notes) { table(:notes) }
    let(:system_note_metadata) { table(:system_note_metadata) }

    def create_system_note(note, metadata_action)
      notes.create(note: note, system: true).tap do |system_note|
        system_note_metadata.create(note_id: system_note.id, action: metadata_action)
      end
    end

    let(:weight_note_with_comma) { create_system_note('changed weight to 5,', 'weight') }
    let(:weight_note_without_comma) { create_system_note('removed the weight', 'weight') }
    let(:title_note) { create_system_note('changed title from 5, to 5,', 'title') }
    let(:user_note) { notes.create(note: 'changed weight to 5,') }

    it 'removes all trailing commas from weight system notes' do
      expect { migrate! }
        .to change { Note.where("note LIKE '%,'").count }.from(3).to(2)
        .and change { weight_note_with_comma.reload.note }
        .and not_change { weight_note_without_comma.reload.note }
        .and not_change { title_note.reload.note }
        .and not_change { user_note.reload.note }
    end
  end
end
