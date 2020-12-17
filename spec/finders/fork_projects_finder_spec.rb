# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ForkProjectsFinder do
  include ProjectForksHelper

  let(:source_project) { create(:project, :public, :empty_repo) }
  let(:private_fork) { fork_project(source_project, nil, name: 'A') }
  let(:internal_fork) { fork_project(source_project, nil, name: 'B') }
  let(:public_fork) { fork_project(source_project, nil, name: 'C') }

  let(:non_member) { create(:user) }
  let(:private_fork_member) { create(:user) }

  before do
    private_fork.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
    private_fork.add_developer(private_fork_member)

    internal_fork.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
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
