require 'spec_helper'

describe LabelsFinder do
  describe '#execute' do
    let(:group_1) { create(:group) }
    let(:group_2) { create(:group) }
    let(:group_3) { create(:group) }

    let(:project_1) { create(:empty_project, namespace: group_1) }
    let(:project_2) { create(:empty_project, namespace: group_2) }
    let(:project_3) { create(:empty_project) }
    let(:project_4) { create(:empty_project, :public) }
    let(:project_5) { create(:empty_project, namespace: group_1) }

    let!(:project_label_1) { create(:label, project: project_1, title: 'Label 1') }
    let!(:project_label_2) { create(:label, project: project_2, title: 'Label 2') }
    let!(:project_label_4) { create(:label, project: project_4, title: 'Label 4') }
    let!(:project_label_5) { create(:label, project: project_5, title: 'Label 5') }

    let!(:group_label_1) { create(:group_label, group: group_1, title: 'Label 1') }
    let!(:group_label_2) { create(:group_label, group: group_1, title: 'Group Label 2') }
    let!(:group_label_3) { create(:group_label, group: group_2, title: 'Group Label 3') }

    let(:user) { create(:user) }

    before do
      create(:label, project: project_3, title: 'Label 3')
      create(:group_label, group: group_3, title: 'Group Label 4')

      project_1.team << [user, :developer]
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
      it 'returns labels available for any project within the group' do
        group_1.add_developer(user)

        finder = described_class.new(user, group_id: group_1.id)

        expect(finder.execute).to eq [group_label_2, project_label_1, group_label_1, project_label_5]
      end
    end

    context 'filtering by project_id' do
      it 'returns labels available for the project' do
        finder = described_class.new(user, project_id: project_1.id)

        expect(finder.execute).to eq [group_label_2, project_label_1, group_label_1]
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
