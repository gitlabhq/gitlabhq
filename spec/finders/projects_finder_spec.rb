require 'spec_helper'

describe ProjectsFinder do
  let(:user) { create :user }
  let(:group) { create :group }
  let(:group2) { create :group }

  let(:project1) { create(:empty_project, :public,   group: group) }
  let(:project2) { create(:empty_project, :internal, group: group) }
  let(:project3) { create(:empty_project, :private,  group: group) }
  let(:project4) { create(:empty_project, :private,  group: group) }
  let(:project5) { create(:empty_project, :private,  group: group2) }
  let(:project6) { create(:empty_project, :internal,  group: group2) }
  let(:project7) { create(:empty_project, :public,  group: group2) }
  let(:project8) { create(:empty_project, :private,  group: group2) }

  context 'non authenticated' do
    subject { ProjectsFinder.new.execute(nil, group: group) }

    it { should include(project1) }
    it { should_not include(project2) }
    it { should_not include(project3) }
    it { should_not include(project4) }
  end

  context 'authenticated' do
    subject { ProjectsFinder.new.execute(user, group: group) }

    it { should include(project1) }
    it { should include(project2) }
    it { should_not include(project3) }
    it { should_not include(project4) }
  end

  context 'authenticated, project member' do
    before { project3.team << [user, :developer] }

    subject { ProjectsFinder.new.execute(user, group: group) }

    it { should include(project1) }
    it { should include(project2) }
    it { should include(project3) }
    it { should_not include(project4) }
  end

  context 'authenticated, group member' do
    before { group.add_user(user, Gitlab::Access::DEVELOPER) }

    subject { ProjectsFinder.new.execute(user, group: group) }

    it { should include(project1) }
    it { should include(project2) }
    it { should include(project3) }
    it { should include(project4) }
  end

  context 'authenticated, group member with project shared with group' do
    before {
      group.add_user(user, Gitlab::Access::DEVELOPER)
      project5.project_group_links.create group_access: Gitlab::Access::MASTER, group: group
    }

    subject { ProjectsFinder.new.execute(user, group: group2) }

    it { should include(project5) }
    it { should include(project6) }
    it { should include(project7) }
    it { should_not include(project8) }
  end
end
