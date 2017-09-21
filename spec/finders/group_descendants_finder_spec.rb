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

  describe '#execute' do
    it 'includes projects' do
      project = create(:project, namespace: group)

      expect(finder.execute).to contain_exactly(project)
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
  end

  context 'with nested groups', :nested_groups do
    let!(:project) { create(:project, namespace: group) }
    let!(:subgroup) { create(:group, parent: group) }

    describe '#execute' do
      it 'contains projects and subgroups' do
        expect(finder.execute).to contain_exactly(subgroup, project)
      end

      context 'with a filter' do
        let(:params) { { filter: 'test' } }

        it 'contains only matching projects and subgroups' do
          matching_project = create(:project, namespace: group, name: 'Testproject')
          matching_subgroup = create(:group, name: 'testgroup', parent: group)

          expect(finder.execute).to contain_exactly(matching_subgroup, matching_project)
        end

        context 'with matching children' do
          it 'includes a group that has a subgroup matching the query' do
            matching_subgroup = create(:group, name: 'testgroup', parent: subgroup)

            expect(finder.execute).to contain_exactly(matching_subgroup)
          end

          it 'includes a group that has a project matching the query' do
            matching_project = create(:project, namespace: subgroup, name: 'Testproject')

            expect(finder.execute).to contain_exactly(matching_project)
          end

          it 'does not include the parent itself' do
            group.update!(name: 'test')

            expect(finder.execute).not_to include(group)
          end
        end
      end
    end

    describe '#total_count' do
      it 'counts the array children were already loaded' do
        finder.instance_variable_set(:@children, [build(:project)])

        expect(finder).not_to receive(:subgroups)
        expect(finder).not_to receive(:projects)

        expect(finder.total_count).to eq(1)
      end

      it 'performs a count without loading children when they are not loaded yet' do
        expect(finder).to receive(:subgroups).and_call_original
        expect(finder).to receive(:projects).and_call_original

        expect(finder.total_count).to eq(2)
      end
    end
  end
end
