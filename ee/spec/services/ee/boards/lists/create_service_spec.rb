require 'spec_helper'

describe Boards::Lists::CreateService do
  describe '#execute' do
    let(:parent) { create(:project) }
    let(:board) { create(:board, project: parent) }
    let(:label) { create(:label, project: parent, name: 'in-progress') }

    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    subject(:service) { described_class.new(parent, user, 'assignee_id' => other_user.id) }

    before do
      parent.add_developer(user)
      parent.add_developer(other_user)

      stub_licensed_features(board_assignee_lists: true)
    end

    it 'creates a new assignee list' do
      list = service.execute(board)

      expect(list.list_type).to eq('assignee')
      expect(list).to be_valid
    end
  end
end
