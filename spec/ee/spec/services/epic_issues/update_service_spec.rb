require 'spec_helper'

describe EpicIssues::UpdateService do
  describe '#execute' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:epic) { create(:epic, group: group) }
    let(:issues) { create_list(:issue, 4) }
    let!(:epic_issue1) { create(:epic_issue, epic: epic, issue: issues[0], relative_position: 3) }
    let!(:epic_issue2) { create(:epic_issue, epic: epic, issue: issues[1], relative_position: 600) }
    let!(:epic_issue3) { create(:epic_issue, epic: epic, issue: issues[2], relative_position: 1200) }
    let!(:epic_issue4) { create(:epic_issue, epic: epic, issue: issues[3], relative_position: 2000) }
    let(:default_position_value) { Gitlab::Database::MAX_INT_VALUE / 2 }

    before do
      group.add_developer(user)
    end

    def order_issue(issue, params)
      described_class.new(issue, user, params ).execute
    end

    def ordered_epics
      EpicIssue.all.order('relative_position, id')
    end

    context 'when moving issues between different epics' do
      before do
        epic_issue3.update_attribute(:epic, create(:epic, group: group))
      end

      let(:params) { { move_before_id: epic_issue3.id, move_after_id: epic_issue4.id } }

      subject { order_issue(epic_issue1, params) }

      it 'returns an error' do
        is_expected.to eq(message: 'Epic issue not found for given params', status: :error, http_status: 404)
      end

      it 'does not change the relative_position values' do
        subject

        expect(epic_issue1.relative_position).to eq(3)
        expect(epic_issue2.relative_position).to eq(600)
        expect(epic_issue3.relative_position).to eq(1200)
        expect(epic_issue4.relative_position).to eq(2000)
      end
    end

    context 'moving issue to the first position' do
      let(:params) { { move_after_id: epic_issue1.id } }

      context 'when some positions are close to each other' do
        before do
          epic_issue2.update_attribute(:relative_position, 4)

          order_issue(epic_issue3, params)
        end

        it 'orders issues correctly' do
          expect(ordered_epics).to eq([epic_issue3, epic_issue1, epic_issue2, epic_issue4])
        end
      end

      context 'when there is enough place between positions' do
        before do
          order_issue(epic_issue3, params)
        end

        it 'orders issues correctly' do
          expect(ordered_epics).to eq([epic_issue3, epic_issue1, epic_issue2, epic_issue4])
        end
      end
    end

    context 'moving issue to the third position' do
      let(:params) { { move_before_id: epic_issue3.id, move_after_id: epic_issue4.id } }

      context 'when some positions are close to each other' do
        before do
          epic_issue2.update_attribute(:relative_position, 1998)
          epic_issue3.update_attribute(:relative_position, 1999)

          order_issue(epic_issue1, params)
        end

        it 'orders issues correctly' do
          expect(ordered_epics).to eq([epic_issue2, epic_issue3, epic_issue1, epic_issue4])
        end
      end

      context 'when all positions are same' do
        before do
          epic_issue1.update_attribute(:relative_position, 10)
          epic_issue2.update_attribute(:relative_position, 10)
          epic_issue3.update_attribute(:relative_position, 10)
          epic_issue4.update_attribute(:relative_position, 10)

          order_issue(epic_issue1, params)
        end

        it 'orders affected 2 issues correctly' do
          expect(epic_issue1.reload.relative_position)
            .to be_between(epic_issue3.reload.relative_position, epic_issue4.reload.relative_position)
        end
      end

      context 'when there is enough place between positions' do
        before do
          order_issue(epic_issue1, params)
        end

        it 'orders issues correctly' do
          expect(ordered_epics).to eq([epic_issue2, epic_issue3, epic_issue1, epic_issue4])
        end
      end
    end

    context 'moving issues to the last position' do
      context 'when index of the last possition is correct' do
        before do
          order_issue(epic_issue1, move_before_id: epic_issue4.id)
        end

        it 'orders issues correctly' do
          expect(ordered_epics).to eq([epic_issue2, epic_issue3, epic_issue4, epic_issue1])
        end
      end
    end
  end
end
