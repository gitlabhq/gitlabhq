require 'spec_helper'

describe ProjectsFinder do
  describe '#execute' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }

    let!(:private_project) do
      create(:project, :private, name: 'A', path: 'A')
    end

    let!(:internal_project) do
      create(:project, :internal, group: group, name: 'B', path: 'B')
    end

    let!(:public_project) do
      create(:project, :public, group: group, name: 'C', path: 'C')
    end

    let(:finder) { described_class.new }

    describe 'without a group' do
      describe 'without a user' do
        subject { finder.execute }

        it { is_expected.to eq([public_project]) }
      end

      describe 'with a user' do
        subject { finder.execute(user) }

        describe 'without private projects' do
          it { is_expected.to eq([public_project, internal_project]) }
        end

        describe 'with private projects' do
          before do
            private_project.team.add_user(user, Gitlab::Access::MASTER)
          end

          it do
            is_expected.to eq([public_project, internal_project,
                               private_project])
          end
        end
      end
    end

    describe 'with a group' do
      describe 'without a user' do
        subject { finder.execute(nil, group: group) }

        it { is_expected.to eq([public_project]) }
      end

      describe 'with a user' do
        subject { finder.execute(user, group: group) }

        it { is_expected.to eq([public_project, internal_project]) }
      end
    end
  end
end
