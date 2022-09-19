# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ProjectsRequiringAuthorizationsRefresh::OnDirectMembershipFinder do
  # rubocop:disable Layout/LineLength

  #  Group X                                      Group A   ------shared with-------------> Group B                                       Group C
  #   | Group X_subgroup_1                          |                                       |                                              |
  #   |  | Project X_subgroup_1 ---shared with----->|  Group A_subgroup_1                   |  Group B_subgroup_1 <--shared with---------  | Group C_subgroup_1
  #   |                                             |   | Project A_subgroup_1              |   | Project B_subgroup_1                     |  | Project C_subgroup_1
  #                                                 |  Group A_subgroup_2                   |  Group B_subgroup_2 <----shared with ------- Project C
  #                                                 |   |Project A_subgroup_2               |  | Project B_subgroup_2

  # rubocop:enable Layout/LineLength

  let_it_be(:group_x) { create(:group) }
  let_it_be(:group_a) { create(:group) }
  let_it_be(:group_b) { create(:group) }
  let_it_be(:group_c) { create(:group) }
  let_it_be(:group_x_subgroup_1) { create(:group, parent: group_x) }
  let_it_be(:group_a_subgroup_1) { create(:group, parent: group_a) }
  let_it_be(:group_a_subgroup_2) { create(:group, parent: group_a) }
  let_it_be(:group_b_subgroup_1) { create(:group, parent: group_b) }
  let_it_be(:group_b_subgroup_2) { create(:group, parent: group_b) }
  let_it_be(:group_c_subgroup_1) { create(:group, parent: group_c) }
  let_it_be(:project_x_subgroup_1) { create(:project, group: group_x_subgroup_1, name: 'project_x_subgroup_1') }
  let_it_be(:project_a_subgroup_1) { create(:project, group: group_a_subgroup_1, name: 'project_a_subgroup_1') }
  let_it_be(:project_a_subgroup_2) { create(:project, group: group_a_subgroup_2, name: 'project_a_subgroup_2') }
  let_it_be(:project_b_subgroup_1) { create(:project, group: group_b_subgroup_1, name: 'project_b_subgroup_1') }
  let_it_be(:project_b_subgroup_2) { create(:project, group: group_b_subgroup_2, name: 'project_b_subgroup_2') }
  let_it_be(:project_c_subgroup_1) { create(:project, group: group_c_subgroup_1, name: 'project_c_subgroup_1') }
  let_it_be(:project_c) { create(:project, group: group_c, name: 'project_c') }

  describe '#execute' do
    context 'projects affected when a new member is added to a specific group (here, `Group B`)' do
      subject(:result) { described_class.new(group_b).execute }

      before do
        create(:project_group_link, project: project_x_subgroup_1, group: group_a_subgroup_1)
        create(:project_group_link, project: project_c, group: group_b_subgroup_2)
        create(:group_group_link, shared_group: group_a, shared_with_group: group_b)
        create(:group_group_link, shared_group: group_c_subgroup_1, shared_with_group: group_b_subgroup_1)
      end

      it 'returns all projects IDs where authorizations need to be created for the user'\
        'due to their new membership being created in `Group B`' do
        new_user = create(:user)
        group_b.add_maintainer(new_user)

        expect(result).to match_array(new_user.authorized_projects.ids)
      end

      it 'includes only the expected projects' do
        expected_projects = Project.id_in(
          [
            project_b_subgroup_1, # direct member of Group B gets access to this project due to group hierarchy
            project_b_subgroup_2, # direct member of Group B gets access to this project due to group hierarchy
            project_c,            # direct member of Group B gets access to this project via project-group share
            project_a_subgroup_1, # direct member of Group B gets access to this project via group share
            project_a_subgroup_2, # direct member of Group B gets access to this project via group share

            # direct member of Group B gets access to any projects shared with groups within its shared groups.
            project_x_subgroup_1
          ]
        )
        # project_c_subgroup_1 is not included in the list because only 'direct' members of
        # `group_b_subgroup_1` gets access to that project via the group-group share.
        expect(result).to match_array(expected_projects.ids)
      end
    end
  end
end
