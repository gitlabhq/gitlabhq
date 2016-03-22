require 'spec_helper'

describe ProjectsFinder do
  describe '#execute' do
    let(:user) { create(:user) }
    let(:group) { create(:group, :public) }

    let!(:private_project) do
      create(:project, :private, name: 'A', path: 'A')
    end

    let!(:internal_project) do
      create(:project, :internal, group: group, name: 'B', path: 'B')
    end

    let!(:public_project) do
      create(:project, :public, group: group, name: 'C', path: 'C')
    end

    let!(:shared_project) do
      create(:project, :private, name: 'D', path: 'D')
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

        describe 'without shared projects' do
          it { is_expected.to eq([public_project, internal_project]) }
        end

        describe 'with shared projects and group membership' do
          before do
            group.add_user(user, Gitlab::Access::DEVELOPER)

            shared_project.project_group_links.
              create(group_access: Gitlab::Access::MASTER, group: group)
          end

          it do
            is_expected.to eq([shared_project, public_project, internal_project])
          end
        end

        describe 'with shared projects and project membership' do
          before do
            shared_project.team.add_user(user, Gitlab::Access::DEVELOPER)

            shared_project.project_group_links.
              create(group_access: Gitlab::Access::MASTER, group: group)
          end

          it do
            is_expected.to eq([shared_project, public_project, internal_project])
          end
        end
      end
    end
  end
end
