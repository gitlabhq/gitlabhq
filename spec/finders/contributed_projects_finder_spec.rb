require 'spec_helper'

describe ContributedProjectsFinder do
  let(:source_user) { create(:user) }
  let(:current_user) { create(:user) }

  let(:finder) { described_class.new(source_user) }

  let!(:public_project) { create(:project, :public) }
  let!(:private_project) { create(:project, :private) }
  let!(:internal_project) { create(:project, :internal) }

  before do
    private_project.add_maintainer(source_user)
    private_project.add_developer(current_user)
    public_project.add_maintainer(source_user)

    create(:push_event, project: public_project, author: source_user)
    create(:push_event, project: private_project, author: source_user)
    create(:push_event, project: internal_project, author: source_user)
  end

  describe 'activity without a current user' do
    subject { finder.execute }

    it { is_expected.to match_array([public_project]) }
  end

  describe 'activity with a current user' do
    subject { finder.execute(current_user) }

    it { is_expected.to match_array([private_project, internal_project, public_project]) }
  end
end
