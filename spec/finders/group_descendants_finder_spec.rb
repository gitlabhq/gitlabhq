# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupDescendantsFinder, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }

  let_it_be_with_reload(:group) do
    create(:group).tap do |g|
      g.add_owner(user)
    end
  end

  let(:params) { {} }

  subject(:finder) do
    described_class.new(current_user: user, parent_group: group, params: params)
  end

  describe '#execute' do
    it 'includes projects' do
      project = create(:project, namespace: group)

      expect(finder.execute).to contain_exactly(project)
    end

    context 'when archived is `true`' do
      let(:params) { { archived: 'true' } }

      it 'includes archived projects' do
        archived_project = create(:project, namespace: group, archived: true)
        project = create(:project, namespace: group)

        expect(finder.execute).to contain_exactly(archived_project, project)
      end
    end

    context 'when archived is `only`' do
      let(:params) { { archived: 'only' } }

      it 'includes only archived projects' do
        archived_project = create(:project, namespace: group, archived: true)
        _project = create(:project, namespace: group)

        expect(finder.execute).to contain_exactly(archived_project)
      end
    end

    it 'does not include archived projects' do
      _archived_project = create(:project, :archived, namespace: group)

      expect(finder.execute).to be_empty
    end

    it 'does not include projects aimed for deletion' do
      _project_aimed_for_deletion =
        create(:project, :archived, marked_for_deletion_at: 2.days.ago, pending_delete: false)

      expect(finder.execute).to be_empty
    end

    context 'with a filter' do
      let(:params) { { filter: 'test' } }

      it 'includes only projects matching the filter' do
        _other_project = create(:project, namespace: group)
        matching_project = create(:project, namespace: group, name: 'testproject')

        expect(finder.execute).to contain_exactly(matching_project)
      end
    end

    it 'sorts elements by name as default' do
      project1 = create(:project, namespace: group, name: 'z')
      project2 = create(:project, namespace: group, name: 'a')

      expect(finder.execute).to match_array([project2, project1])
    end

    context 'when sorting by name' do
      let_it_be(:project1) { create(:project, namespace: group, name: 'a', path: 'project-a') }
      let_it_be(:project2) { create(:project, namespace: group, name: 'z', path: 'project-z') }
      let(:params) { { sort: 'name_asc' } }

      it 'sorts elements by name' do
        expect(finder.execute).to eq(
          [
            project1,
            project2
          ]
        )
      end

      context 'with nested groups' do
        let_it_be(:subgroup1) { create(:group, parent: group, name: 'a', path: 'sub-a') }
        let_it_be(:subgroup2) { create(:group, parent: group, name: 'z', path: 'sub-z') }

        it 'sorts elements by name' do
          expect(finder.execute).to eq(
            [
              subgroup1,
              subgroup2,
              project1,
              project2
            ]
          )
        end
      end
    end

    it 'does not include projects shared with the group' do
      project = create(:project, namespace: group)
      other_project = create(:project)
      other_project.project_group_links.create!(
        group: group,
        group_access: Gitlab::Access::MAINTAINER
      )

      expect(finder.execute).to contain_exactly(project)
    end
  end

  context 'with shared groups' do
    let_it_be(:other_group) { create(:group) }
    let_it_be(:shared_group_link) do
      create(
        :group_group_link,
        shared_group: group,
        shared_with_group: other_group
      )
    end

    context 'without common ancestor' do
      it { expect(finder.execute).to be_empty }
    end

    context 'with common ancestor' do
      let_it_be(:common_ancestor) { create(:group) }
      let_it_be(:other_group) { create(:group, parent: common_ancestor) }
      let_it_be(:group) { create(:group, parent: common_ancestor) }

      context 'when querying under the common ancestor' do
        it { expect(finder.execute).to be_empty }
      end

      context 'when querying the common ancestor' do
        subject(:finder) do
          described_class.new(current_user: user, parent_group: common_ancestor, params: params)
        end

        it 'contains shared subgroups' do
          expect(finder.execute).to contain_exactly(group, other_group)
        end
      end
    end
  end

  context 'with nested groups' do
    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be_with_reload(:subgroup) { create(:group, :private, parent: group) }

    describe '#execute' do
      it 'contains projects and subgroups' do
        expect(finder.execute).to contain_exactly(subgroup, project)
      end

      it 'does not include subgroups the user does not have access to' do
        subgroup.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

        public_subgroup = create(:group, :public, parent: group, path: 'public-group')
        other_subgroup = create(:group, :private, parent: group, path: 'visible-private-group')
        other_user = create(:user)
        other_subgroup.add_developer(other_user)

        finder = described_class.new(current_user: other_user, parent_group: group)

        expect(finder.execute).to contain_exactly(public_subgroup, other_subgroup)
      end

      it 'only includes public groups when no user is given' do
        public_subgroup = create(:group, :public, parent: group)
        _private_subgroup = create(:group, :private, parent: group)

        finder = described_class.new(current_user: nil, parent_group: group)

        expect(finder.execute).to contain_exactly(public_subgroup)
      end

      context 'when archived is `true`' do
        let(:params) { { archived: 'true' } }

        it 'includes archived projects in the count of subgroups' do
          create(:project, namespace: subgroup, archived: true)

          expect(finder.execute.first.preloaded_project_count).to eq(1)
        end
      end

      context 'with a filter' do
        let(:params) { { filter: 'test' } }

        it 'contains only matching projects and subgroups' do
          matching_project = create(:project, namespace: group, name: 'Testproject')
          matching_subgroup = create(:group, name: 'testgroup', parent: group)

          expect(finder.execute).to contain_exactly(matching_subgroup, matching_project)
        end

        it 'does not include subgroups the user does not have access to' do
          _invisible_subgroup = create(:group, :private, parent: group, name: 'test1')
          other_subgroup = create(:group, :private, parent: group, name: 'test2')
          public_subgroup = create(:group, :public, parent: group, name: 'test3')
          other_subsubgroup = create(:group, :private, parent: other_subgroup, name: 'test4')
          other_user = create(:user)
          other_subgroup.add_developer(other_user)

          finder = described_class.new(
            current_user: other_user,
            parent_group: group,
            params: params
          )

          expect(finder.execute).to contain_exactly(other_subgroup, public_subgroup, other_subsubgroup)
        end

        context 'with page param' do
          let_it_be(:params) { { page: 2, per_page: 1, filter: 'test' } }
          let_it_be(:matching_subgroup1) { create(:group, :private, name: 'testgroup1', parent: group) }
          let_it_be(:matching_subgroup2) { create(:group, :private, name: 'testgroup2', parent: group) }

          it 'does not include items from previous pages' do
            expect(finder.execute).to contain_exactly(matching_subgroup2)
          end
        end

        context 'with matching children' do
          it 'includes a group that has a subgroup matching the query and its parent' do
            matching_subgroup = create(:group, :private, name: 'testgroup', parent: subgroup)

            expect(finder.execute).to contain_exactly(subgroup, matching_subgroup)
          end

          it 'includes the parent of a matching project' do
            matching_project = create(:project, namespace: subgroup, name: 'Testproject')

            expect(finder.execute).to contain_exactly(subgroup, matching_project)
          end

          context 'with a small page size' do
            let(:params) { { filter: 'test', per_page: 1 } }

            it 'contains all the ancestors of a matching subgroup regardless the page size' do
              subgroup = create(:group, :private, parent: group)
              matching = create(:group, :private, name: 'testgroup', parent: subgroup)

              expect(finder.execute).to contain_exactly(subgroup, matching)
            end
          end

          it 'does not include the parent itself' do
            group.update!(name: 'test')

            expect(finder.execute).not_to include(group)
          end
        end

        context 'when items more than Kaminari.config.default_per_page' do
          let_it_be(:filter) { 'filtered-group' }
          let_it_be(:per_page) { 2 }
          let_it_be(:params) { { filter: filter } }
          let_it_be(:subgroups) { Array.new(per_page) { create(:group, parent: group) } }
          let_it_be(:sub_subgroups) { subgroups.map { |subgroup| create(:group, parent: subgroup) } }
          let_it_be(:matching_descendants) do
            sub_subgroups.map.with_index do |sub_subgroup, index|
              Array.new(per_page) do |descendant_index|
                formatted_index = "#{index}#{descendant_index}"
                create(:group, :public, parent: sub_subgroup, name: "#{filter}-#{formatted_index}")
              end
            end.flatten
          end

          before do
            allow(Kaminari.config).to receive(:default_per_page).and_return(per_page)
          end

          it 'returns the correct descendants with their ancestors' do
            expect(finder.execute).to contain_exactly(
              subgroups.first,
              sub_subgroups.first,
              *matching_descendants.first(2)
            )
          end
        end
      end
    end
  end
end
