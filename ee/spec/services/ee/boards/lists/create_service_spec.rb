require 'spec_helper'

describe Boards::Lists::CreateService do
  describe '#execute' do
    let(:project) { create(:project) }
    let(:board) { create(:board, project: project) }

    context 'when assignee_id param is sent' do
      let(:user) { create(:user) }
      let(:other_user) { create(:user) }
      subject(:service) { described_class.new(project, user, 'assignee_id' => other_user.id) }

      before do
        project.add_developer(user)
        project.add_developer(other_user)

        stub_licensed_features(board_assignee_lists: true)
      end

      it 'creates a new assignee list' do
        list = service.execute(board)

        expect(list.list_type).to eq('assignee')
        expect(list).to be_valid
      end
    end

    context 'when milestone_id param is sent' do
      let(:user) { create(:user) }
      let(:milestone) { create(:milestone, project: project) }
      subject(:service) { described_class.new(project, user, 'milestone_id' => milestone.id) }

      before do
        project.add_developer(user)

        stub_licensed_features(board_milestone_lists: true)
      end

      it 'creates a milestone list when param is valid' do
        list = service.execute(board)

        expect(list.list_type).to eq('milestone')
        expect(list).to be_valid
      end
    end
  end
end
