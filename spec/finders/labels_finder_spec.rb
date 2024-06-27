# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LabelsFinder, feature_category: :team_planning do
  describe '#execute' do
    let_it_be(:group_1) { create(:group) }
    let_it_be(:group_2) { create(:group) }
    let_it_be(:group_3) { create(:group) }
    let_it_be(:private_group_1) { create(:group, :private) }
    let_it_be(:private_subgroup_1) { create(:group, :private, parent: private_group_1) }

    let_it_be(:project_1, reload: true) { create(:project, namespace: group_1) }
    let_it_be(:project_2) { create(:project, namespace: group_2) }
    let_it_be(:project_3) { create(:project) }
    let_it_be(:project_4) { create(:project, :public) }
    let_it_be(:project_5) { create(:project, namespace: group_1) }

    let_it_be(:project_label_1) { create(:label, project: project_1, title: 'Label 1', description: 'awesome label name') }
    let_it_be(:project_label_2) { create(:label, project: project_2, title: 'Label 2') }
    let_it_be(:project_label_4) { create(:label, project: project_4, title: 'Renamed', description: 'old label 5') }
    let_it_be(:project_label_5) { create(:label, project: project_5, title: 'Label 5') }
    let_it_be(:project_label_locked) { create(:label, project: project_1, title: 'Label Locked', lock_on_merge: true) }

    let_it_be(:group_label_1) { create(:group_label, group: group_1, title: 'Label 1 (group)') }
    let_it_be(:group_label_2) { create(:group_label, group: group_1, title: 'Group Label 2') }
    let_it_be(:group_label_3) { create(:group_label, group: group_2, title: 'Group Label 3') }
    let_it_be(:group_label_locked) { create(:group_label, group: group_1, title: 'Group Label Locked', lock_on_merge: true) }
    let_it_be(:private_group_label_1) { create(:group_label, group: private_group_1, title: 'Private Group Label 1') }
    let_it_be(:private_subgroup_label_1) { create(:group_label, group: private_subgroup_1, title: 'Private Sub Group Label 1') }

    let_it_be(:unused_label) { create(:label, project: project_3, title: 'Label 3') }
    let_it_be(:unused_group_label) { create(:group_label, group: group_3, title: 'Group Label 4') }

    let_it_be(:user) { create(:user) }

    before do
      project_1.add_developer(user)
    end

    context 'with no filter' do
      it 'returns labels from projects the user have access' do
        group_2.add_developer(user)

        finder = described_class.new(user)

        expect(finder.execute).to match_array([group_label_2, group_label_3, group_label_locked, project_label_1, group_label_1, project_label_2, project_label_4, project_label_locked])
      end

      it 'returns labels available if nil title is supplied' do
        group_2.add_developer(user)
        # params[:title] will return `nil` regardless whether it is specified
        finder = described_class.new(user, title: nil)

        expect(finder.execute).to match_array([group_label_2, group_label_3, group_label_locked, project_label_1, group_label_1, project_label_2, project_label_4, project_label_locked])
      end
    end

    shared_examples 'filtering by group' do
      it 'returns labels available for any non-archived project within the group' do
        group_1.add_developer(user)
        ::Projects::UpdateService.new(project_1, user, archived: true).execute
        finder = described_class.new(user, **group_params(group_1))

        expect(finder.execute).to match_array([group_label_2, group_label_1, project_label_5, group_label_locked])
      end

      context 'when only_group_labels is true' do
        it 'returns only group labels' do
          group_1.add_developer(user)

          finder = described_class.new(user, only_group_labels: true, **group_params(group_1))

          expect(finder.execute).to match_array([group_label_2, group_label_1, group_label_locked])
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
            finder = described_class.new(user, **group_params(empty_group))

            expect(finder.execute).to match_array([empty_group_label_1, empty_group_label_2])
          end
        end
      end

      context 'when including labels from group ancestors' do
        it 'returns labels from group and its ancestors' do
          private_group_1.add_developer(user)
          private_subgroup_1.add_developer(user)

          finder = described_class.new(user, **group_params(private_subgroup_1), only_group_labels: true, include_ancestor_groups: true)

          expect(finder.execute).to match_array([private_group_label_1, private_subgroup_label_1])
        end

        it 'ignores labels from groups which user can not read' do
          private_subgroup_1.add_developer(user)

          finder = described_class.new(user, **group_params(private_subgroup_1), only_group_labels: true, include_ancestor_groups: true)

          expect(finder.execute).to match_array([private_subgroup_label_1])
        end
      end

      context 'when including labels from group descendants' do
        it 'returns labels from group and its descendants' do
          private_group_1.add_developer(user)
          private_subgroup_1.add_developer(user)

          finder = described_class.new(user, **group_params(private_group_1), only_group_labels: true, include_descendant_groups: true)

          expect(finder.execute).to match_array([private_group_label_1, private_subgroup_label_1])
        end

        it 'ignores labels from groups which user can not read' do
          private_subgroup_1.add_developer(user)

          finder = described_class.new(user, **group_params(private_group_1), only_group_labels: true, include_descendant_groups: true)

          expect(finder.execute).to match_array([private_subgroup_label_1])
        end
      end

      context 'when including labels from group projects with limited visibility' do
        let(:finder)                     { described_class.new(user, **group_params(group_4)) }
        let(:group_4)                    { create(:group) }
        let(:limited_visibility_project) { create(:project, :public, group: group_4) }
        let(:visible_project)            { create(:project, :public, group: group_4) }
        let!(:group_label_1)             { create(:group_label, group: group_4) }
        let!(:limited_visibility_label)  { create(:label, project: limited_visibility_project) }
        let!(:visible_label)             { create(:label, project: visible_project) }

        shared_examples 'with full visibility' do
          it 'returns all projects labels' do
            expect(finder.execute).to match_array([group_label_1, limited_visibility_label, visible_label])
          end
        end

        shared_examples 'with limited visibility' do
          it 'returns only authorized projects labels' do
            expect(finder.execute).to match_array([group_label_1, visible_label])
          end
        end

        context 'when merge requests and issues are not visible for non members' do
          before do
            limited_visibility_project.project_feature.update!(
              merge_requests_access_level: ProjectFeature::PRIVATE,
              issues_access_level: ProjectFeature::PRIVATE
            )
          end

          context 'when user is not a group member' do
            it_behaves_like 'with limited visibility'
          end

          context 'when user is a group member' do
            before do
              group_4.add_developer(user)
            end

            it_behaves_like 'with full visibility'
          end
        end

        context 'when merge requests are not visible for non members' do
          before do
            limited_visibility_project.project_feature.update!(
              merge_requests_access_level: ProjectFeature::PRIVATE
            )
          end

          context 'when user is not a group member' do
            it_behaves_like 'with full visibility'
          end

          context 'when user is a group member' do
            before do
              group_4.add_developer(user)
            end

            it_behaves_like 'with full visibility'
          end
        end

        context 'when issues are not visible for non members' do
          before do
            limited_visibility_project.project_feature.update!(
              issues_access_level: ProjectFeature::PRIVATE
            )
          end

          context 'when user is not a group member' do
            it_behaves_like 'with full visibility'
          end

          context 'when user is a group member' do
            before do
              group_4.add_developer(user)
            end

            it_behaves_like 'with full visibility'
          end
        end
      end
    end

    it_behaves_like 'filtering by group' do
      def group_params(group)
        { group: group }
      end
    end

    it_behaves_like 'filtering by group' do
      def group_params(group)
        { group_id: group.id }
      end
    end

    it_behaves_like 'filtering by group' do
      def group_params(group)
        { group: '', group_id: group.id }
      end
    end

    context 'filtering by project_id' do
      context 'when include_ancestor_groups is true' do
        let_it_be(:sub_project) { create(:project, namespace: private_subgroup_1) }
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

        expect(finder.execute).to match_array([group_label_2, group_label_locked, project_label_1, project_label_locked, group_label_1])
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

        expect(finder.execute).to match_array([group_label_2])
      end

      it 'returns label with title alias' do
        finder = described_class.new(user, name: 'Group Label 2')

        expect(finder.execute).to match_array([group_label_2])
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

    context 'search by title and description' do
      it 'returns labels with a partially matching title' do
        finder = described_class.new(user, search: '(group)')

        expect(finder.execute).to match_array([group_label_1])
      end

      it 'returns labels with a partially matching description' do
        finder = described_class.new(user, search: 'awesome')

        expect(finder.execute).to match_array([project_label_1])
      end

      it 'returns labels matching a single character' do
        finder = described_class.new(user, search: '(')

        expect(finder.execute).to match_array([group_label_1])
      end
    end

    context 'when searching by title only' do
      it 'returns labels partially matching the title' do
        finder = described_class.new(user, search: 'label', search_in: [:title])

        expect(finder.execute).to match_array([group_label_1, group_label_2, group_label_locked, project_label_1, project_label_locked])
      end

      it 'returns label matching the "name" in their title' do
        finder = described_class.new(user, search: 'name', search_in: [:title])

        expect(finder.execute).to match_array([project_label_4])
      end
    end

    context 'when searching by description only' do
      it 'returns labels partially matching the description' do
        finder = described_class.new(user, search: 'label', search_in: [:description])

        expect(finder.execute).to match_array([project_label_1, project_label_4])
      end
    end

    context 'filter by subscription' do
      it 'returns labels user subscribed to' do
        project_label_1.subscribe(user)

        finder = described_class.new(user, subscribed: 'true')

        expect(finder.execute).to match_array([project_label_1])
      end
    end

    context 'filter by locked labels' do
      it 'returns labels that are locked' do
        finder = described_class.new(user, locked_labels: true)

        expect(finder.execute).to match_array([project_label_locked, group_label_locked])
      end
    end

    context 'external authorization' do
      it_behaves_like 'a finder with external authorization service' do
        let!(:subject) { create(:label, project: project) }
        let(:project_params) { { project_id: project.id } }
      end
    end
  end
end
