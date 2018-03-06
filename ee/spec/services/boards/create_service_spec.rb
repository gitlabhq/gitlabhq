require 'spec_helper'

describe Boards::CreateService, services: true do
  shared_examples 'board with milestone predefined scope' do
    let(:project) { create(:project) }

    it 'creates board with correct milestone' do
      stub_licensed_features(scoped_issue_board: true)

      board = described_class
        .new(project, double, milestone_id: milestone_class.id)
        .execute

      expect(board.reload.milestone).to eq(milestone_class)
    end
  end

  shared_examples 'boards create service' do
    context 'With the feature available' do
      before do
        stub_licensed_features(multiple_group_issue_boards: true)
      end

      context 'with valid params' do
        subject(:service) { described_class.new(parent, double, name: 'Backend') }

        it 'creates a new board' do
          expect { service.execute }.to change(parent.boards, :count).by(1)
        end

        it 'creates the default lists' do
          board = service.execute

          expect(board.lists.size).to eq 2
          expect(board.lists.first).to be_backlog
          expect(board.lists.last).to be_closed
        end
      end

      context 'with invalid params' do
        subject(:service) { described_class.new(parent, double, name: nil) }

        it 'does not create a new parent board' do
          expect { service.execute }.not_to change(parent.boards, :count)
        end

        it "does not create board's default lists" do
          board = service.execute

          expect(board.lists.size).to eq 0
        end
      end

      context 'without params' do
        subject(:service) { described_class.new(parent, double) }

        it 'creates a new parent board' do
          expect { service.execute }.to change(parent.boards, :count).by(1)
        end

        it "creates board's default lists" do
          board = service.execute

          expect(board.lists.size).to eq 2
          expect(board.lists.last).to be_closed
        end
      end
    end

    it 'skips creating a second board when the feature is not available' do
      stub_licensed_features(multiple_project_issue_boards: false)
      service = described_class.new(parent, double)

      expect(service.execute).not_to be_nil

      expect { service.execute }.not_to change(parent.boards, :count)
    end
  end

  describe '#execute' do
    it_behaves_like 'boards create service' do
      let(:parent) { create(:project, :empty_repo) }
    end

    it_behaves_like 'boards create service' do
      let(:parent) { create(:group) }
    end

    it_behaves_like 'board with milestone predefined scope' do
      let(:milestone_class) { ::Milestone::Upcoming }
    end

    it_behaves_like 'board with milestone predefined scope' do
      let(:milestone_class) { ::Milestone::Started }
    end

    context 'group board milestone' do
      let(:group) { create(:group) }
      let!(:milestone) { create(:milestone) }

      before do
        stub_licensed_features(scoped_issue_board: true)
      end

      it 'is not persisted if it is not within group milestones' do
        service = described_class.new(group, double, milestone_id: milestone.id)

        group_board = service.execute

        expect(group_board.milestone).to be_nil
      end

      it 'is persisted if it is within group milestones' do
        milestone.update!(project: nil, group: group)
        service = described_class.new(group, double, milestone_id: milestone.id)

        group_board = service.execute

        expect(group_board.reload.milestone).to eq(milestone)
      end
    end

    context 'project board milestone' do
      let(:project) { create(:project, :private) }
      let!(:milestone) { create(:milestone) }

      before do
        stub_licensed_features(scoped_issue_board: true)
      end

      it 'is not persisted if it is not within project milestones' do
        service = described_class.new(project, double, milestone_id: milestone.id)

        board = service.execute

        expect(board.reload.milestone).to be_nil
      end

      it 'is persisted if it is within project milestones' do
        milestone.update!(project: project)
        service = described_class.new(project, double, milestone_id: milestone.id)

        board = service.execute

        expect(board.reload.milestone).to eq(milestone)
      end

      it 'is persisted if it is within project group milestones' do
        project_group = create(:group)
        project.update(group: project_group)
        milestone.update!(project: nil, group: project_group)

        service = described_class.new(project_group, double, milestone_id: milestone.id)

        board = service.execute

        expect(board.reload.milestone).to eq(milestone)
      end
    end
  end
end
