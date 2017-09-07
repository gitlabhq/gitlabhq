require 'spec_helper'

describe Boards::Lists::CreateService, services: true do
  describe '#execute' do
    let(:group) { create(:group) }
    let(:board)   { create(:board, group: group) }
    let(:user)    { create(:user) }
    let(:label)   { create(:group_label, group: group, name: 'in-progress') }

    subject(:service) { described_class.new(group, user, label_id: label.id) }

    before do
      group.add_developer(user)
    end

    context 'when board lists is empty' do
      it 'creates a new list at beginning of the list' do
        list = service.execute(board)

        expect(list.position).to eq 0
      end
    end

    context 'when board lists has the done list' do
      it 'creates a new list at beginning of the list' do
        list = service.execute(board)

        expect(list.position).to eq 0
      end
    end

    context 'when board lists has labels lists' do
      it 'creates a new list at end of the lists' do
        create(:list, board: board, position: 0)
        create(:list, board: board, position: 1)

        list = service.execute(board)

        expect(list.position).to eq 2
      end
    end

    context 'when board lists has label and done lists' do
      it 'creates a new list at end of the label lists' do
        list1 = create(:list, board: board, position: 0)

        list2 = service.execute(board)

        expect(list1.reload.position).to eq 0
        expect(list2.reload.position).to eq 1
      end
    end

    context 'when provided label does not belongs to the group' do
      it 'raises an error' do
        label = create(:label, name: 'in-development')
        service = described_class.new(group, user, label_id: label.id)

        expect { service.execute(board) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
