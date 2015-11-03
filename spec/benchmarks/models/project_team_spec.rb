require 'spec_helper'

describe ProjectTeam, benchmark: true do
  describe '#max_member_access' do
    let(:group)   { create(:group) }
    let(:project) { create(:empty_project, group: group) }
    let(:user)    { create(:user) }

    before do
      project.team << [user, :master]

      5.times do
        project.team << [create(:user), :reporter]

        project.group.add_user(create(:user), :reporter)
      end
    end

    benchmark_subject { project.team.max_member_access(user.id) }

    it { is_expected.to iterate_per_second(35000) }
  end
end
