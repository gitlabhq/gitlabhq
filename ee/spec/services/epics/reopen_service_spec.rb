# frozen_string_literal: true
require 'spec_helper'

describe Epics::ReopenService do
  let(:group) { create(:group, :internal) }
  let(:user) { create(:user) }
  let(:epic) { create(:epic, group: group, state: :closed, closed_at: Date.today, closed_by: user) }

  describe '#execute' do
    subject { described_class.new(group, user) }

    context 'when epics are disabled' do
      before do
        group.add_master(user)
      end

      it 'does not reopen the epic' do
        expect { subject.execute(epic) }.not_to change { epic.state }
      end
    end

    context 'when epics are enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when a user has permissions to update the epic' do
        before do
          group.add_master(user)
        end

        context 'when reopening a closed epic' do
          it 'reopens the epic' do
            expect { subject.execute(epic) }.to change { epic.state }.from('closed').to('opened')
          end

          it 'removes closed_by' do
            expect { subject.execute(epic) }.to change { epic.closed_by }.to(nil)
          end

          it 'removes closed_at' do
            expect { subject.execute(epic) }.to change { epic.closed_at }.to(nil)
          end
        end

        context 'when trying to reopen an opened epic' do
          before do
            epic.update(state: :opened)
          end

          it 'does not change the epic state' do
            expect { subject.execute(epic) }.not_to change { epic.state }
          end

          it 'does not change closed_at' do
            expect { subject.execute(epic) }.not_to change { epic.closed_at }
          end

          it 'does not change closed_by' do
            expect { subject.execute(epic) }.not_to change { epic.closed_by }
          end
        end
      end

      context 'when a user does not have permissions to update epic' do
        it 'does not reopen the epic' do
          expect { subject.execute(epic) }.not_to change { epic.state }
        end
      end
    end
  end
end
