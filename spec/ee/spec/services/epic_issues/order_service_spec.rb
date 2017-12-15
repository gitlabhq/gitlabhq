require 'spec_helper'

describe EpicIssues::OrderService do
  describe '#execute' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:epic) { create(:epic, group: group) }
    let(:issues) { create_list(:issue, 4) }
    let!(:epic_issue1) { create(:epic_issue, epic: epic, issue: issues[0], position: 1) }
    let!(:epic_issue2) { create(:epic_issue, epic: epic, issue: issues[1], position: 2) }
    let!(:epic_issue3) { create(:epic_issue, epic: epic, issue: issues[2], position: 3) }
    let!(:epic_issue4) { create(:epic_issue, epic: epic, issue: issues[3], position: 4) }

    before do
      group.add_developer(user)
    end

    def order_issue(issue, new_order)
      described_class.new(issue, user, { position: new_order } ).execute
    end

    def ordered_epics
      EpicIssue.all.order(:position)
    end

    context 'moving issue to the first position' do
      it 'orders issues correctly' do
        order_issue(epic_issue3, 1)

        expect(ordered_epics).to eq([epic_issue3, epic_issue1, epic_issue2, epic_issue4])
      end

      context 'when some order values are missing ' do
        before do
          epic_issue1.update_attribute(:position, 3)
          epic_issue2.update_attribute(:position, 6)
          epic_issue3.update_attribute(:position, 10)
          epic_issue4.update_attribute(:position, 15)
        end

        it 'orders issues correctly' do
          order_issue(epic_issue3, 1)

          expect(ordered_epics).to eq([epic_issue3, epic_issue1, epic_issue2, epic_issue4])
        end

        it 'updates all affected issues positions by 1' do
          order_issue(epic_issue3, 1)

          expect(epic_issue3.reload.position).to eq(1)
          expect(epic_issue1.reload.position).to eq(4)
          expect(epic_issue2.reload.position).to eq(7)
          expect(epic_issue4.reload.position).to eq(15)
        end
      end
    end

    context 'moving issue to the third position' do
      it 'orders issues correctly' do
        order_issue(epic_issue1, 3)

        expect(ordered_epics).to eq([epic_issue2, epic_issue3, epic_issue1, epic_issue4])
      end

      context 'when some order values are missing ' do
        before do
          epic_issue1.update_attribute(:position, 3)
          epic_issue2.update_attribute(:position, 6)
          epic_issue3.update_attribute(:position, 10)
          epic_issue4.update_attribute(:position, 15)
        end

        it 'orders issues correctly' do
          order_issue(epic_issue1, 10)

          expect(ordered_epics).to eq([epic_issue2, epic_issue3, epic_issue1, epic_issue4])
        end

        it 'updates all affected issues positions by 1' do
          order_issue(epic_issue3, 1)

          expect(epic_issue3.reload.position).to eq(1)
          expect(epic_issue1.reload.position).to eq(4)
          expect(epic_issue2.reload.position).to eq(7)
          expect(epic_issue4.reload.position).to eq(15)
        end
      end
    end
  end
end
