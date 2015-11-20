require 'spec_helper'

describe ProjectsFinder do
<<<<<<< HEAD
  let(:user) { create :user }
  let(:group) { create :group }
  let(:group2) { create :group }

  let(:project1) { create(:empty_project, :public,   group: group) }
  let(:project2) { create(:empty_project, :internal, group: group) }
  let(:project3) { create(:empty_project, :private,  group: group) }
  let(:project4) { create(:empty_project, :private,  group: group) }
  let(:project5) { create(:empty_project, :private,  group: group2) }
  let(:project6) { create(:empty_project, :internal,  group: group2) }
  let(:project7) { create(:empty_project, :public,  group: group2) }
  let(:project8) { create(:empty_project, :private,  group: group2) }
=======
  describe '#execute' do
    let(:user) { create(:user) }

    let!(:private_project)  { create(:project, :private) }
    let!(:internal_project) { create(:project, :internal) }
    let!(:public_project)   { create(:project, :public) }
>>>>>>> b6f0eddce552d7423869e9072a7a0706e309dbdf

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
      let(:group) { public_project.group }

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

  context 'authenticated, group member with project shared with group' do
    before do
      group.add_user(user, Gitlab::Access::DEVELOPER)
      project5.project_group_links.create group_access: Gitlab::Access::MASTER, group: group
    end

    subject { ProjectsFinder.new.execute(user, group: group2) }

    it { should include(project5) }
    it { should include(project6) }
    it { should include(project7) }
    it { should_not include(project8) }
  end
end
