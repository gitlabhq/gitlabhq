# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::AcceptingProjectSharesFinder, feature_category: :groups_and_projects do
  subject(:result) { described_class.new(current_user, project, params).execute }

  let_it_be_with_reload(:current_user) { create(:user) }
  let_it_be(:group_1) { create(:group) }
  let_it_be(:group_1_subgroup) { create(:group, parent: group_1) }
  let_it_be(:group_2) { create(:group, name: 'hello-world-group') }
  let_it_be(:group_3) { create(:group) }
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, group: group) }

  let(:params) { {} }

  context 'when admin', :enable_admin_mode do
    let_it_be(:current_user) { create(:admin) }

    it 'returns all groups' do
      expect(result).to match_array([group_1, group_1_subgroup, group_2, group_3])
    end
  end

  context 'when normal user' do
    context 'when the user has no access to the project to be shared' do
      it 'does not return any group' do
        expect(result).to be_empty
      end
    end

    context 'when the user has no access to any group' do
      before do
        project.add_maintainer(current_user)
      end

      it 'does not return any group' do
        expect(result).to be_empty
      end
    end

    context "when the project's group has enabled lock on group sharing" do
      before do
        project.add_maintainer(current_user)
        project.namespace.update!(share_with_group_lock: true)
        group_1.add_maintainer(current_user)
      end

      it 'does not return any group' do
        expect(result).to be_empty
      end
    end

    context 'when the user has access to groups' do
      before do
        project.add_maintainer(current_user)

        group_1.add_guest(current_user)
        group_2.add_guest(current_user)
      end

      it 'returns groups where the user has at least guest access' do
        expect(result).to match_array([group_1, group_1_subgroup, group_2])
      end

      context 'when searching' do
        let(:params) { { search: 'hello' } }

        it 'returns groups where the search term matches' do
          expect(result).to match_array([group_2])
        end
      end
    end

    context 'for sharing outside hierarchy' do
      let_it_be_with_reload(:grandparent_group) { create(:group) }
      let_it_be(:child_group) { create(:group, parent: grandparent_group) }
      let_it_be(:grandchild_group) { create(:group, parent: child_group) }
      let_it_be(:grandchild_group_subgroup) { create(:group, parent: grandchild_group) }
      let_it_be(:unrelated_group) { create(:group) }
      let_it_be_with_reload(:project) { create(:project, group: child_group) }

      before do
        project.add_maintainer(current_user)

        grandparent_group.add_guest(current_user)
        unrelated_group.add_guest(current_user)
      end

      context 'when sharing outside hierarchy is allowed' do
        before do
          grandparent_group.namespace_settings.update!(prevent_sharing_groups_outside_hierarchy: false)
        end

        it 'returns all groups where the user has at least guest access' do
          expect(result).to match_array([grandchild_group, grandchild_group_subgroup, unrelated_group])
        end
      end

      context 'when sharing outside hierarchy is not allowed' do
        before do
          grandparent_group.namespace_settings.update!(prevent_sharing_groups_outside_hierarchy: true)
        end

        it 'returns groups where the user has at least guest access, but only from within the hierarchy' do
          expect(result).to match_array([grandchild_group, grandchild_group_subgroup])
        end

        context 'when groups are already linked to the project' do
          before do
            create(:project_group_link, project: project, group: grandchild_group_subgroup)
          end

          it 'does not appear in the result' do
            expect(result).to match_array([grandchild_group])
          end
        end
      end
    end
  end
end
