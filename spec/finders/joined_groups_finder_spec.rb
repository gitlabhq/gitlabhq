require 'spec_helper'

describe JoinedGroupsFinder do
  describe '#execute' do
    let(:source_user) { create(:user) }
    let(:current_user) { create(:user) }

    let(:group1) { create(:group) }
    let(:group2) { create(:group) }
    let(:group3) { create(:group) }
    let(:group4) { create(:group, public: true) }

    let!(:public_project)   { create(:project, :public, group: group1) }
    let!(:internal_project) { create(:project, :internal, group: group2) }
    let!(:private_project)  { create(:project, :private, group: group3) }

    let(:finder) { described_class.new(source_user) }

    before do
      [group1, group2, group3, group4].each do |group|
        group.add_user(source_user, Gitlab::Access::MASTER)
      end
    end

    describe 'with a current user' do
      describe 'when the current user has access to the projects of the source user' do
        before do
          private_project.team.add_user(current_user, Gitlab::Access::DEVELOPER)
        end

        subject { finder.execute(current_user) }

        it { is_expected.to eq([group4, group3, group2, group1]) }
      end

      describe 'when the current user does not have access to the projects of the source user' do
        subject { finder.execute(current_user) }

        it { is_expected.to eq([group4, group2, group1]) }
      end
    end

    describe 'without a current user' do
      subject { finder.execute }

      it { is_expected.to eq([group4, group1]) }
    end
  end
end
