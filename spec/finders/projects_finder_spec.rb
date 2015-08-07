require 'spec_helper'

describe ProjectsFinder do
  let(:user) { create :user }
  let(:group) { create :group }

  let(:project1) { create(:empty_project, :public,   group: group) }
  let(:project2) { create(:empty_project, :internal, group: group) }
  let(:project3) { create(:empty_project, :private,  group: group) }
  let(:project4) { create(:empty_project, :private,  group: group) }

  context 'non authenticated' do
    subject { ProjectsFinder.new.execute(nil, group: group) }

    it { is_expected.to include(project1) }
    it { is_expected.not_to include(project2) }
    it { is_expected.not_to include(project3) }
    it { is_expected.not_to include(project4) }
  end

  context 'authenticated' do
    subject { ProjectsFinder.new.execute(user, group: group) }

    it { is_expected.to include(project1) }
    it { is_expected.to include(project2) }
    it { is_expected.not_to include(project3) }
    it { is_expected.not_to include(project4) }
  end

  context 'authenticated, project member' do
    before { project3.team << [user, :developer] }

    subject { ProjectsFinder.new.execute(user, group: group) }

    it { is_expected.to include(project1) }
    it { is_expected.to include(project2) }
    it { is_expected.to include(project3) }
    it { is_expected.not_to include(project4) }
  end

  context 'authenticated, group member' do
    before { group.add_developer(user) }

    subject { ProjectsFinder.new.execute(user, group: group) }

    it { is_expected.to include(project1) }
    it { is_expected.to include(project2) }
    it { is_expected.to include(project3) }
    it { is_expected.to include(project4) }
  end
end
