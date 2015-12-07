require 'spec_helper'

describe GroupsFinder do
  describe '#execute' do
    let(:user) { create(:user) }

    let(:group1) { create(:group) }
    let(:group2) { create(:group) }
    let(:group3) { create(:group) }
    let(:group4) { create(:group, public: true) }

    let!(:public_project)   { create(:project, :public, group: group1) }
    let!(:internal_project) { create(:project, :internal, group: group2) }
    let!(:private_project)  { create(:project, :private, group: group3) }

    let(:finder) { described_class.new }

    describe 'with a user' do
      subject { finder.execute(user) }

      describe 'when the user is not a member of any groups' do
        it { is_expected.to eq([group4, group2, group1]) }
      end

      describe 'when the user is a member of a group' do
        before do
          group3.add_user(user, Gitlab::Access::DEVELOPER)
        end

        it { is_expected.to eq([group4, group3, group2, group1]) }
      end

      describe 'when the user is a member of a private project' do
        before do
          private_project.team.add_user(user, Gitlab::Access::DEVELOPER)
        end

        it { is_expected.to eq([group4, group3, group2, group1]) }
      end
    end

    describe 'without a user' do
      subject { finder.execute }

      it { is_expected.to eq([group4, group1]) }
    end
  end
end
