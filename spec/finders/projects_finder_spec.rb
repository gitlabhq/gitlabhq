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
          is_expected.to eq([public_project, internal_project, private_project])
        end
      end
    end

    describe 'with project_ids_relation' do
      let(:project_ids_relation) { Project.where(id: internal_project.id) }

      subject { finder.execute(user, project_ids_relation) }

      it { is_expected.to eq([internal_project]) }
    end
  end
end
