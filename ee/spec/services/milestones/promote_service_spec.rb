require 'spec_helper'

describe Milestones::PromoteService do
  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: group) }
  let(:user) { create(:user) }
  let(:milestone_title) { 'project milestone' }
  let(:milestone) { create(:milestone, project: project, title: milestone_title) }
  let!(:board) { create(:board, project: project, milestone: milestone) }
  let(:service) { described_class.new(project, user) }

  describe '#execute' do
    before do
      group.add_maintainer(user)
    end

    it 'updates board with new milestone' do
      promoted_milestone = service.execute(milestone)

      expect(board.reload.milestone).to eq(promoted_milestone)
      expect(promoted_milestone.group_milestone?).to be_truthy
    end
  end
end
