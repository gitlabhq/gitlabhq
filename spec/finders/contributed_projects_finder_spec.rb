require 'spec_helper'

describe ContributedProjectsFinder do
  let(:source_user) { create(:user) }
  let(:current_user) { create(:user) }

  let(:finder) { described_class.new(source_user) }

  let!(:public_project) { create(:empty_project, :public) }
  let!(:private_project) { create(:empty_project, :private) }

  before do
    private_project.add_master(source_user)
    private_project.add_developer(current_user)
    public_project.add_master(source_user)

    create(:event, :pushed, project: public_project, target: public_project, author: source_user)
    create(:event, :pushed, project: private_project, target: private_project, author: source_user)
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
