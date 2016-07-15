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

  describe '#execute' do
    let(:params)  { { target_id: commit.id, target_type: 'commit', last_fetched_at: 1.hour.ago.to_i } }

    before do
      note1
      note2
    end

    it 'should find all notes' do
      notes = NotesFinder.new.execute(project, user, params)
      expect(notes.size).to eq(2)
    end

    it 'should raise an exception for an invalid target_type' do
      params.merge!(target_type: 'invalid')
      expect { NotesFinder.new.execute(project, user, params) }.to raise_error('invalid target_type')
    end

    it 'filters out old notes' do
      note2.update_attribute(:updated_at, 2.hours.ago)
      notes = NotesFinder.new.execute(project, user, params)
      expect(notes).to eq([note1])
    end

    context 'confidential issue notes' do
      let(:confidential_issue) { create(:issue, :confidential, project: project, author: user) }
      let!(:confidential_note) { create(:note, noteable: confidential_issue, project: confidential_issue.project) }

      let(:params) { { target_id: confidential_issue.id, target_type: 'issue', last_fetched_at: 1.hour.ago.to_i } }

      it 'returns notes if user can see the issue' do
        expect(NotesFinder.new.execute(project, user, params)).to eq([confidential_note])
      end

      it 'raises an error if user can not see the issue' do
        user = create(:user)
        expect { NotesFinder.new.execute(project, user, params) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'raises an error for project members with guest role' do
        user = create(:user)
        project.team << [user, :guest]

        expect { NotesFinder.new.execute(project, user, params) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
