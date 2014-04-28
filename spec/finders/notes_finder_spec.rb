require 'spec_helper'

describe NotesFinder do
  let(:user) { create :user }
  let(:project) { create :project }
  let(:note1) { create :note_on_commit, project: project }
  let(:note2) { create :note_on_commit, project: project }
  let(:commit) { note1.noteable }

  before do
    project.team << [user, :master]
  end

  describe :execute do
    before do
      note1
      note2
    end

    it 'should find all notes' do
      params = { target_id: commit.id, target_type: 'commit' }
      notes = NotesFinder.new.execute(project, user, params)
      notes.size.should eq(2)
    end

    it 'should raise an exception for an invalid target_type' do
      params = { target_id: commit.id, target_type: 'invalid' }
      expect { NotesFinder.new.execute(project, user, params) }.to raise_error('invalid target_type')
    end

    it 'filters out old notes' do
      note2.update_attribute(:updated_at, 2.hours.ago)
      params = { target_id: commit.id, target_type: 'commit', last_fetched_at: 1.hour.ago }
      notes = NotesFinder.new.execute(project, user, params)
      notes.should eq([note1])
    end
  end
end
