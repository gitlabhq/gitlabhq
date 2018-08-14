# frozen_string_literal: true
require 'spec_helper'

describe Notes::QuickActionsService do
  let(:group)   { create(:group) }
  let(:project) { create(:project, group: group) }
  let(:user) { create(:user) }
  let(:issue) { create(:issue, project: project) }
  let(:epic) { create(:epic, group: group)}

  let(:service) { described_class.new(project, user) }

  before do
    project.add_maintainer(user)
  end

  def execute(note)
    content, command_params = service.extract_commands(note)
    service.execute(command_params, note)

    content
  end

  describe '/epic' do
    let(:note_text) { "/epic #{epic.to_reference(project)}" }
    let(:note) { create(:note_on_issue, noteable: issue, project: project, note: note_text) }

    before do
      group.add_developer(user)
    end

    context 'when epics are not enabled' do
      it 'does not assign the epic' do
        expect(execute(note)).to be_empty
        expect(issue.epic).to be_nil
      end
    end

    context 'when epics are enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'on an issue' do
        it 'assigns the issue to the epic' do
          expect { execute(note) }.to change { issue.reload.epic }.from(nil).to(epic)
        end

        it 'leaves the note empty' do
          expect(execute(note)).to eq('')
        end

        it 'creates a system note' do
          expect { execute(note) }.to change { Note.system.count }.from(0).to(2)
        end
      end

      context 'on a merge request' do
        let(:note_mr) { create(:note_on_merge_request, project: project, note: note_text) }

        it 'leaves the note empty' do
          expect(execute(note_mr)).to be_empty
        end
      end
    end
  end

  describe '/remove_epic' do
    let(:note_text) { "/remove_epic" }
    let(:note) { create(:note_on_issue, noteable: issue, project: project, note: note_text) }

    before do
      issue.update!(epic: epic)
      group.add_developer(user)
    end

    context 'when epics are not enabled' do
      it 'does not remove the epic' do
        expect(execute(note)).to be_empty
        expect(issue.epic).to eq(epic)
      end
    end

    context 'when epics are enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'on an issue' do
        it 'removes the epic' do
          expect { execute(note) }.to change { issue.reload.epic }.from(epic).to(nil)
        end

        it 'leaves the note empty' do
          expect(execute(note)).to eq('')
        end

        it 'creates a system note' do
          expect { execute(note) }.to change { Note.system.count }.from(0).to(2)
        end
      end

      context 'on a merge request' do
        let(:note_mr) { create(:note_on_merge_request, project: project, note: note_text) }

        it 'leaves the note empty' do
          expect(execute(note_mr)).to be_empty
        end
      end
    end
  end
end
