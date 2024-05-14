# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContributedProjectsFinder, feature_category: :groups_and_projects do
  let(:source_user) { create(:user) }
  let(:current_user) { create(:user) }

  let(:finder) { described_class.new(source_user) }

  let!(:public_project) { create(:project, :public) }
  let!(:private_project) { create(:project, :private) }
  let!(:internal_project) { create(:project, :internal) }

  let(:default_ordering) { [internal_project, private_project, public_project] }

  before do
    private_project.add_maintainer(source_user)
    private_project.add_developer(current_user)
    public_project.add_maintainer(source_user)

    travel_to(4.hours.from_now) { create(:push_event, project: private_project, author: source_user) }
    travel_to(3.hours.from_now) { create(:push_event, project: internal_project, author: source_user) }
    travel_to(2.hours.from_now) { create(:push_event, project: public_project, author: source_user) }
  end

  context 'when order_by is specified' do
    subject { finder.execute(current_user, order_by: 'latest_activity_desc') }

    it { is_expected.to eq([private_project, internal_project, public_project]) }
  end

  describe 'activity without a current user' do
    it 'does only return public projects' do
      projects = finder.execute
      expect(projects).to match_array([public_project])
    end

    it 'does return all projects when visibility gets ignored' do
      projects = finder.execute(ignore_visibility: true)
      expect(projects).to eq(default_ordering)
    end
  end

  describe 'activity with a current user' do
    subject { finder.execute(current_user) }

    it { is_expected.to eq(default_ordering) }
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
