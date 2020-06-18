# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContributedProjectsFinder do
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

  context 'user with private profile' do
    it 'does not return contributed projects' do
      private_user = create(:user, private_profile: true)
      public_project.add_maintainer(private_user)
      create(:push_event, project: public_project, author: private_user)

      projects = described_class.new(private_user).execute(current_user)

      expect(projects).to be_empty
    end
  end
end
