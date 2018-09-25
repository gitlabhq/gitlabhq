# frozen_string_literal: true
require 'spec_helper'

describe Epics::CloseService do
  let(:group) { create(:group, :internal) }
  let(:user) { create(:user) }
  let(:epic) { create(:epic, group: group) }

  describe '#execute' do
    subject { described_class.new(group, user) }

    context 'when epics are disabled' do
      before do
        group.add_master(user)
      end

      it 'does not close the epic' do
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

        context 'when closing an opened epic' do
          it 'closes the epic' do
            expect { subject.execute(epic) }.to change { epic.state }.from('opened').to('closed')
          end

          it 'changes closed_by' do
            expect { subject.execute(epic) }.to change { epic.closed_by }.to(user)
          end

          it 'changes closed_at' do
            expect { subject.execute(epic) }.to change { epic.closed_at }
          end
        end

        context 'when trying to close a closed epic' do
          before do
            epic.update(state: :closed)
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
        it 'does not close the epic' do
          expect { subject.execute(epic) }.not_to change { epic.state }
        end
      end
    end
  end
end
