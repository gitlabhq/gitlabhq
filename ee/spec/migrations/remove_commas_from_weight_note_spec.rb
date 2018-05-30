require 'spec_helper'
require Rails.root.join('ee', 'db', 'migrate', '../../db/migrate/20180530201303_remove_commas_from_weight_note.rb')

describe RemoveCommasFromWeightNote, :migration do
  let(:migration) { described_class.new }

  describe '#up' do
    let(:notes) {table(:notes)}

    let!(:note_1) {notes.create(note: 'changed weight to 5,')}
    let!(:note_2) {notes.create(note: 'removed the weight')}

    it 'removes all trailing commas' do
      expect { migrate! }.to change { Note.where("note LIKE '%,'").count }.from(1).to(0)
    end
  end

  describe '#down' do
    let(:notes) {table(:notes)}

    let!(:note_1) {notes.create(note: 'changed weight to 5')}
    let!(:note_2) {notes.create(note: 'removed the weight')}

    it 'adds trailing commas' do
      expect { migration.down }.to change { Note.where("note LIKE '%,'").count }.from(0).to(1)
    end
  end
end
