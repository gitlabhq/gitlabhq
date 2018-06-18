require 'spec_helper'

describe Boards::UsersFinder do
  describe '#execute' do
    subject { described_class.new(board) }

    context 'when parent is a project' do
      let(:project) { create(:project) }
      let(:board) { create(:board, project: project) }

      it 'finds ProjectMembers with MemberFinder' do
        results = subject.execute

        expect(subject.instance_variable_get(:@finder_service)).to be_kind_of(MembersFinder)
        expect(results.first).to be_kind_of(ProjectMember)
      end
    end

    context 'when parent is a group' do
      let(:group) { create(:group) }
      let(:board) { create(:board, group: group) }
      let(:user) { create(:user) }

      before do
        group.add_developer(user)
      end

      it 'finds GroupMembers with GroupMemberFinder' do
        results = subject.execute

        expect(subject.instance_variable_get(:@finder_service)).to be_kind_of(GroupMembersFinder)
        expect(results.first).to be_kind_of(GroupMember)
      end
    end
  end
end
