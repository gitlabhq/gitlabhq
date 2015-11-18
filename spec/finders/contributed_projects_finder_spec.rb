require 'spec_helper'

describe ContributedProjectsFinder do
  let(:source_user) { create(:user) }
  let(:current_user) { create(:user) }

  let(:finder) { described_class.new(source_user) }

  let!(:public_project) { create(:project, :public) }
  let!(:private_project) { create(:project, :private) }

  before do
    private_project.team << [source_user, Gitlab::Access::MASTER]
    private_project.team << [current_user, Gitlab::Access::DEVELOPER]
    public_project.team << [source_user, Gitlab::Access::MASTER]

    create(:event, action: Event::PUSHED, project: public_project,
                   target: public_project, author: source_user)

    create(:event, action: Event::PUSHED, project: private_project,
                   target: private_project, author: source_user)
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
