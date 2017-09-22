require 'spec_helper'

describe ForkProjectsFinder do
  let(:source_project) { create(:project, :empty_repo) }
  let(:private_fork) { create(:project, :private, :empty_repo, name: 'A') }
  let(:internal_fork) { create(:project, :internal, :empty_repo, name: 'B') }
  let(:public_fork) { create(:project, :public, :empty_repo, name: 'C') }

  let(:non_member) { create(:user) }
  let(:private_fork_member) { create(:user) }

  before do
    private_fork.add_developer(private_fork_member)

    source_project.forks << private_fork
    source_project.forks << internal_fork
    source_project.forks << public_fork
  end

  describe '#execute' do
    let(:finder) { described_class.new(source_project, params: {}, current_user: current_user) }

    subject { finder.execute }

    describe 'without a user' do
      let(:current_user) { nil }

      it { is_expected.to eq([public_fork]) }
    end

    describe 'with a user' do
      let(:current_user) { non_member }

      it { is_expected.to eq([public_fork, internal_fork]) }
    end

    describe 'with a member' do
      let(:current_user) { private_fork_member }

      it { is_expected.to eq([public_fork, internal_fork, private_fork]) }
    end
  end
end
