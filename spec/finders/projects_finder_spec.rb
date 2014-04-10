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
end
