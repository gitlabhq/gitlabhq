require 'spec_helper'

describe PersonalProjectsFinder do
  let(:source_user) { create(:user) }
  let(:current_user) { create(:user) }

  let(:finder) { described_class.new(source_user) }

  let!(:public_project) do
    create(:project, :public, namespace: source_user.namespace, name: 'A',
                              path: 'A')
  end

  let!(:private_project) do
    create(:project, :private, namespace: source_user.namespace, name: 'B',
                               path: 'B')
  end

  before do
    private_project.team << [current_user, Gitlab::Access::DEVELOPER]
  end

  describe 'without a current user' do
    subject { finder.execute }

    it { is_expected.to eq([public_project]) }
  end

  describe 'with a current user' do
    subject { finder.execute(current_user) }

    it { is_expected.to eq([private_project, public_project]) }
  end
end
