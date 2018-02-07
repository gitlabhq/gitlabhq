require 'spec_helper'

describe GroupDescendantsFinder do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:params) { {} }
  subject(:finder) do
    described_class.new(current_user: user, parent_group: group, params: params)
  end

  before do
    group.add_owner(user)
  end

  describe '#has_children?' do
    it 'is true when there are projects' do
      create(:project, namespace: group)

      expect(finder.has_children?).to be_truthy
    end

    context 'when there are subgroups', :nested_groups do
      it 'is true when there are projects' do
        create(:group, parent: group)

        expect(finder.has_children?).to be_truthy
      end
    end
  end

  describe '#execute' do
    it 'includes projects' do
      project = create(:project, namespace: group)

      expect(finder.execute).to contain_exactly(project)
    end

    it 'does not include projects shared with the group' do
      project = create(:project, namespace: group)
      other_project = create(:project)
      other_project.project_group_links.create(group: group,
                                               group_access: ProjectGroupLink::MASTER)

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

    context 'with a filter' do
      let(:params) { { filter: 'test' } }

      it 'includes only projects matching the filter' do
        _other_project = create(:project, namespace: group)
        matching_project = create(:project, namespace: group, name: 'testproject')

        expect(finder.execute).to contain_exactly(matching_project)
      end
    end

    context 'sorting by name' do
      let!(:project1) { create(:project, namespace: group, name: 'a', path: 'project-a') }
      let!(:project2) { create(:project, namespace: group, name: 'z', path: 'project-z') }
      let(:params) do
        {
          sort: 'name_asc'
        }
      end

      it 'sorts elements by name' do
        expect(subject.execute).to eq(
          [
            project1,
            project2
          ]
        )
      end

      context 'with nested groups', :nested_groups do
        let!(:subgroup1) { create(:group, parent: group, name: 'a', path: 'sub-a') }
        let!(:subgroup2) { create(:group, parent: group, name: 'z', path: 'sub-z') }

        it 'sorts elements by name' do
          expect(subject.execute).to eq(
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
  end

  context 'with nested groups', :nested_groups do
    let!(:project) { create(:project, namespace: group) }
    let!(:subgroup) { create(:group, :private, parent: group) }

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

          finder = described_class.new(current_user: other_user,
                                       parent_group: group,
                                       params: params)

          expect(finder.execute).to contain_exactly(other_subgroup, public_subgroup, other_subsubgroup)
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
      end
    end
  end
end
