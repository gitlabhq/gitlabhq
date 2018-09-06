# frozen_string_literal: true
require 'spec_helper'

describe Issues::UpdateService do
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }
  let(:issue) { create(:issue, project: project) }
  let(:user) { issue.author }

  describe 'execute' do
    def update_issue(opts)
      described_class.new(project, user, opts).execute(issue)
    end

    context 'refresh epic dates' do
      let(:epic) { create(:epic) }
      let(:issue) { create(:issue, epic: epic) }

      context 'updating milestone' do
        let(:milestone) { create(:milestone) }

        it 'calls epic#update_start_and_due_dates' do
          expect(epic).to receive(:update_start_and_due_dates).twice

          update_issue(milestone: milestone)
          update_issue(milestone_id: nil)
        end
      end

      context 'updating other fields' do
        it 'does not call epic#update_start_and_due_dates' do
          expect(epic).not_to receive(:update_start_and_due_dates)
          update_issue(title: 'foo')
        end
      end
    end

    context 'assigning epic' do
      before do
        stub_licensed_features(epics: true)
        group.add_maintainer(user)
      end

      let(:epic) { create(:epic, group: group) }

      context 'when issue does not belong to an epic yet' do
        it 'assigns an issue to the provided epic' do
          expect { update_issue(epic: epic) }.to change { issue.reload.epic }.from(nil).to(epic)
        end

        it 'creates system notes for the epic and the issue' do
          expect { update_issue(epic: epic) }.to change { Note.count }.from(0).to(2)

          epic_note = Note.find_by(noteable_id: epic.id, noteable_type: 'Epic')
          issue_note = Note.find_by(noteable_id: issue.id, noteable_type: 'Issue')

          expect(epic_note.system_note_metadata.action).to eq('epic_issue_added')
          expect(issue_note.system_note_metadata.action).to eq('issue_added_to_epic')
        end
      end

      context 'when issue does belongs to another epic' do
        let(:epic2) { create(:epic, group: group) }

        before do
          issue.update!(epic: epic2)
        end

        it 'assigns the issue passed to the provided epic' do
          expect { update_issue(epic: epic) }.to change { issue.reload.epic }.from(epic2).to(epic)
        end

        it 'creates system notes for the epic and the issue' do
          expect { update_issue(epic: epic) }.to change { Note.count }.from(0).to(3)

          epic_note = Note.find_by(noteable_id: epic.id, noteable_type: 'Epic')
          epic2_note = Note.find_by(noteable_id: epic2.id, noteable_type: 'Epic')
          issue_note = Note.find_by(noteable_id: issue.id, noteable_type: 'Issue')

          expect(epic_note.system_note_metadata.action).to eq('epic_issue_moved')
          expect(epic2_note.system_note_metadata.action).to eq('epic_issue_moved')
          expect(issue_note.system_note_metadata.action).to eq('issue_changed_epic')
        end
      end
    end

    context 'removing epic' do
      before do
        stub_licensed_features(epics: true)
        group.add_maintainer(user)
      end

      let(:epic) { create(:epic, group: group) }

      context 'when issue does not belong to an epic yet' do
        it 'does not do anything' do
          expect { update_issue(epic: nil) }.not_to change { issue.reload.epic }
        end
      end

      context 'when issue does belongs to an epic' do
        before do
          issue.update!(epic: epic)
        end

        it 'assigns a new issue to the provided epic' do
          expect { update_issue(epic: nil) }.to change { issue.reload.epic }.from(epic).to(nil)
        end

        it 'creates system notes for the epic and the issue' do
          expect { update_issue(epic: nil) }.to change { Note.count }.from(0).to(2)

          epic_note = Note.find_by(noteable_id: epic.id, noteable_type: 'Epic')
          issue_note = Note.find_by(noteable_id: issue.id, noteable_type: 'Issue')

          expect(epic_note.system_note_metadata.action).to eq('epic_issue_removed')
          expect(issue_note.system_note_metadata.action).to eq('issue_removed_from_epic')
        end
      end
    end
  end
end
