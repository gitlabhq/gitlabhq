require 'spec_helper'

describe LabelsFinder do
  describe '#execute' do
    let(:group_1) { create(:group) }
    let(:group_2) { create(:group) }
    let(:group_3) { create(:group) }
    let(:private_group_1) { create(:group, :private) }
    let(:private_subgroup_1) { create(:group, :private, parent: private_group_1) }

    let(:project_1) { create(:project, namespace: group_1) }
    let(:project_2) { create(:project, namespace: group_2) }
    let(:project_3) { create(:project) }
    let(:project_4) { create(:project, :public) }
    let(:project_5) { create(:project, namespace: group_1) }

    let!(:project_label_1) { create(:label, project: project_1, title: 'Label 1') }
    let!(:project_label_2) { create(:label, project: project_2, title: 'Label 2') }
    let!(:project_label_4) { create(:label, project: project_4, title: 'Label 4') }
    let!(:project_label_5) { create(:label, project: project_5, title: 'Label 5') }

    let!(:group_label_1) { create(:group_label, group: group_1, title: 'Label 1 (group)') }
    let!(:group_label_2) { create(:group_label, group: group_1, title: 'Group Label 2') }
    let!(:group_label_3) { create(:group_label, group: group_2, title: 'Group Label 3') }
    let!(:private_group_label_1) { create(:group_label, group: private_group_1, title: 'Private Group Label 1') }
    let!(:private_subgroup_label_1) { create(:group_label, group: private_subgroup_1, title: 'Private Sub Group Label 1') }

    let(:user) { create(:user) }

    before do
      create(:label, project: project_3, title: 'Label 3')
      create(:group_label, group: group_3, title: 'Group Label 4')

      project_1.add_developer(user)
    end

    context 'with no filter' do
      it 'returns labels from projects the user have access' do
        group_2.add_developer(user)

        finder = described_class.new(user)

        expect(finder.execute).to eq [group_label_2, group_label_3, project_label_1, group_label_1, project_label_2, project_label_4]
      end

      it 'returns labels available if nil title is supplied' do
        group_2.add_developer(user)
        # params[:title] will return `nil` regardless whether it is specified
        finder = described_class.new(user, title: nil)

        expect(finder.execute).to eq [group_label_2, group_label_3, project_label_1, group_label_1, project_label_2, project_label_4]
      end
    end

    context 'filtering by group_id' do
      it 'returns labels available for any non-archived project within the group' do
        group_1.add_developer(user)
        project_1.archive!
        finder = described_class.new(user, group_id: group_1.id)

        expect(finder.execute).to eq [group_label_2, group_label_1, project_label_5]
      end

      context 'when only_group_labels is true' do
        it 'returns only group labels' do
          group_1.add_developer(user)

          finder = described_class.new(user, group_id: group_1.id, only_group_labels: true)

          expect(finder.execute).to eq [group_label_2, group_label_1]
        end
      end

      context 'when group has no projects' do
        let(:empty_group) { create(:group) }
        let!(:empty_group_label_1) { create(:group_label, group: empty_group, title: 'Label 1 (empty group)') }
        let!(:empty_group_label_2) { create(:group_label, group: empty_group, title: 'Label 2 (empty group)') }

        before do
          empty_group.add_developer(user)
        end

        context 'when only group labels is false' do
          it 'returns group labels' do
            finder = described_class.new(user, group_id: empty_group.id)

            expect(finder.execute).to eq [empty_group_label_1, empty_group_label_2]
          end
        end
      end

      context 'when including labels from group ancestors', :nested_groups do
        it 'returns labels from group and its ancestors' do
          private_group_1.add_developer(user)
          private_subgroup_1.add_developer(user)

          finder = described_class.new(user, group_id: private_subgroup_1.id, only_group_labels: true, include_ancestor_groups: true)

          expect(finder.execute).to eq [private_group_label_1, private_subgroup_label_1]
        end

        it 'ignores labels from groups which user can not read' do
          private_subgroup_1.add_developer(user)

          finder = described_class.new(user, group_id: private_subgroup_1.id, only_group_labels: true, include_ancestor_groups: true)

          expect(finder.execute).to eq [private_subgroup_label_1]
        end
      end

      context 'when including labels from group descendants', :nested_groups do
        it 'returns labels from group and its descendants' do
          private_group_1.add_developer(user)
          private_subgroup_1.add_developer(user)

          finder = described_class.new(user, group_id: private_group_1.id, only_group_labels: true, include_descendant_groups: true)

          expect(finder.execute).to eq [private_group_label_1, private_subgroup_label_1]
        end

        it 'ignores labels from groups which user can not read' do
          private_subgroup_1.add_developer(user)

          finder = described_class.new(user, group_id: private_group_1.id, only_group_labels: true, include_descendant_groups: true)

          expect(finder.execute).to eq [private_subgroup_label_1]
        end
      end
    end

    context 'filtering by project_id', :nested_groups do
      context 'when include_ancestor_groups is true' do
        let!(:sub_project) { create(:project, namespace: private_subgroup_1 ) }
        let!(:project_label) { create(:label, project: sub_project, title: 'Label 5') }
        let(:finder) { described_class.new(user, project_id: sub_project.id, include_ancestor_groups: true) }

        before do
          private_group_1.add_developer(user)
        end

        it 'returns all ancestor labels' do
          expect(finder.execute).to match_array([private_subgroup_label_1, private_group_label_1, project_label])
        end
      end

      it 'returns labels available for the project' do
        finder = described_class.new(user, project_id: project_1.id)

        expect(finder.execute).to eq [group_label_2, project_label_1, group_label_1]
      end

      context 'as an administrator' do
        it 'does not return labels from another project' do
          # Purposefully creating a project with _nothing_ associated to it
          isolated_project = create(:project)
          admin = create(:admin)

          # project_3 has a label associated to it, which we don't want coming
          # back when we ask for the isolated project's labels
          project_3.add_reporter(admin)
          finder = described_class.new(admin, project_id: isolated_project.id)

          expect(finder.execute).to be_empty
        end
      end
    end

    context 'filtering by title' do
      it 'returns label with that title' do
        finder = described_class.new(user, title: 'Group Label 2')

        expect(finder.execute).to eq [group_label_2]
      end

      it 'returns label with title alias' do
        finder = described_class.new(user, name: 'Group Label 2')

        expect(finder.execute).to eq [group_label_2]
      end

      it 'returns no labels if empty title is supplied' do
        finder = described_class.new(user, title: [])

        expect(finder.execute).to be_empty
      end

      it 'returns no labels if blank title is supplied' do
        finder = described_class.new(user, title: '')

        expect(finder.execute).to be_empty
      end

      it 'returns no labels if empty name is supplied' do
        finder = described_class.new(user, name: [])

        expect(finder.execute).to be_empty
      end
    end
  end
end
