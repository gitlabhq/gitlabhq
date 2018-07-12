require 'spec_helper'

describe EpicIssues::DestroyService do
  describe '#execute' do
    let(:user) { create(:user) }
    let(:group) { create(:group, :public) }
    let(:project) { create(:project, group: group) }
    let(:epic) { create(:epic, group: group) }
    let(:issue) { create(:issue, project: project) }
    let!(:epic_issue) { create(:epic_issue, epic: epic, issue: issue) }

    subject { described_class.new(epic_issue, user).execute }

    context 'when epics feature is disabled' do
      before do
        group.add_reporter(user)
      end

      it 'returns an error' do
        is_expected.to eq(message: 'No Issue Link found', status: :error, http_status: 404)
      end
    end

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when user has permissions to remove associations' do
        before do
          group.add_reporter(user)
        end

        it 'removes related issue' do
          expect { subject }.to change { EpicIssue.count }.from(1).to(0)
        end

        it 'returns success message' do
          is_expected.to eq(message: 'Relation was removed', status: :success)
        end

        it 'creates 2 system notes' do
          expect { subject }.to change { Note.count }.from(0).to(2)
        end

        it 'creates a note for epic correctly' do
          subject
          note = Note.find_by(noteable_id: epic.id, noteable_type: 'Epic')

          expect(note.note).to eq("removed issue #{issue.to_reference(epic.group)}")
          expect(note.author).to eq(user)
          expect(note.project).to be_nil
          expect(note.noteable_type).to eq('Epic')
          expect(note.system_note_metadata.action).to eq('epic_issue_removed')
        end

        it 'creates a note for issue correctly' do
          subject
          note = Note.find_by(noteable_id: issue.id, noteable_type: 'Issue')

          expect(note.note).to eq("removed from epic #{epic.to_reference(issue.project)}")
          expect(note.author).to eq(user)
          expect(note.project).to eq(issue.project)
          expect(note.noteable_type).to eq('Issue')
          expect(note.system_note_metadata.action).to eq('issue_removed_from_epic')
        end
      end

      context 'user does not have permissions to remove associations' do
        it 'does not remove relation' do
          expect { subject }.not_to change { EpicIssue.count }.from(1)
        end

        it 'returns error message' do
          is_expected.to eq(message: 'No Issue Link found', status: :error, http_status: 404)
        end
      end

      context 'refresh epic dates' do
        it 'calls epic#update_dates' do
          expect(epic).to receive(:update_dates)
          subject
        end
      end
    end
  end
end
