require 'spec_helper'

describe Boards::UpdateService, services: true do
  shared_examples 'board with milestone predefined scope' do
    let(:project) { create(:project) }
    let!(:board)  { create(:board) }

    it 'updates board to milestone id' do
      stub_licensed_features(scoped_issue_board: true)

      described_class
        .new(project, double, milestone_id: milestone_class.id)
        .execute(board)

      expect(board.reload.milestone).to eq(milestone_class)
    end
  end

  describe '#execute' do
    let(:project) { create(:project) }
    let(:group) { create(:group) }
    let!(:board)  { create(:board, group: group, name: 'Backend') }

    it "updates board's name" do
      service = described_class.new(group, double, name: 'Engineering')

      service.execute(board)

      expect(board).to have_attributes(name: 'Engineering')
    end

    it 'returns true with valid params' do
      service = described_class.new(group, double, name: 'Engineering')

      expect(service.execute(board)).to eq true
    end

    it 'returns false with invalid params' do
      service = described_class.new(group, double, name: nil)

      expect(service.execute(board)).to eq false
    end

    it 'updates the configuration params when scoped issue board is enabled' do
      stub_licensed_features(scoped_issue_board: true)
      assignee = create(:user)
      milestone = create(:milestone, project: project)
      label = create(:label, project: project)

      service = described_class.new(project, double,
                                    milestone_id: milestone.id,
                                    assignee_id: assignee.id,
                                    label_ids: [label.id])
      service.execute(board)

      expect(board.reload).to have_attributes(milestone: milestone,
                                              assignee: assignee,
                                              labels: [label])
    end

    it 'filters unpermitted params when scoped issue board is not enabled' do
      stub_licensed_features(scoped_issue_board: false)
      params = { milestone_id: double, assignee_id: double, label_ids: double, weight: double }

      service = described_class.new(project, double, params)
      service.execute(board)

      expect(board.reload).to have_attributes(milestone: nil,
                                              assignee: nil,
                                              labels: [])
    end

    it_behaves_like 'board with milestone predefined scope' do
      let(:milestone_class) { ::Milestone::Upcoming }
    end

    it_behaves_like 'board with milestone predefined scope' do
      let(:milestone_class) { ::Milestone::Started }
    end

    context 'group board milestone' do
      let(:group) { create(:group) }
      let(:group_board) { create(:board, group: group, name: 'Backend Group') }
      let!(:milestone) { create(:milestone) }

      before do
        stub_licensed_features(scoped_issue_board: true)
      end

      it 'is not updated if it is not within group milestones' do
        service = described_class.new(group, double, milestone_id: milestone.id)

        service.execute(group_board)

        expect(group_board.reload.milestone).to be_nil
      end

      it 'is updated if it is within group milestones' do
        milestone.update!(project: nil, group: group)
        service = described_class.new(group, double, milestone_id: milestone.id)

        service.execute(group_board)

        expect(group_board.reload.milestone).to eq(milestone)
      end
    end

    context 'project board milestone' do
      let!(:milestone) { create(:milestone) }

      before do
        stub_licensed_features(scoped_issue_board: true)
      end

      it 'is not updated if it is not within project milestones' do
        service = described_class.new(project, double, milestone_id: milestone.id)

        service.execute(board)

        expect(board.reload.milestone).to be_nil
      end

      it 'is updated if it is within project milestones' do
        milestone.update!(project: project)
        service = described_class.new(project, double, milestone_id: milestone.id)

        service.execute(board)

        expect(board.reload.milestone).to eq(milestone)
      end

      it 'is updated if it is within project group milestones' do
        project_group = create(:group)
        project.update(group: project_group)
        milestone.update!(project: nil, group: project_group)

        service = described_class.new(project_group, double, milestone_id: milestone.id)

        service.execute(board)

        expect(board.reload.milestone).to eq(milestone)
      end
    end
  end
end
