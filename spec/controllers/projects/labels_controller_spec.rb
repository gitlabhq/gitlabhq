require 'spec_helper'

describe Projects::LabelsController do
  let(:group)   { create(:group) }
  let(:project) { create(:project, namespace: group) }
  let(:user)    { create(:user) }

  before do
    project.team << [user, :master]

    sign_in(user)
  end

  describe 'GET #index' do
    let!(:label_1) { create(:label, project: project, priority: 1, title: 'Label 1') }
    let!(:label_2) { create(:label, project: project, priority: 3, title: 'Label 2') }
    let!(:label_3) { create(:label, project: project, priority: 1, title: 'Label 3') }
    let!(:label_4) { create(:label, project: project, priority: nil, title: 'Label 4') }
    let!(:label_5) { create(:label, project: project, priority: nil, title: 'Label 5') }

    let!(:group_label_1) { create(:group_label, group: group, priority: 3, title: 'Group Label 1') }
    let!(:group_label_2) { create(:group_label, group: group, priority: 1, title: 'Group Label 2') }
    let!(:group_label_3) { create(:group_label, group: group, priority: nil, title: 'Group Label 3') }
    let!(:group_label_4) { create(:group_label, group: group, priority: nil, title: 'Group Label 4') }

    context '@prioritized_labels' do
      before do
        list_labels
      end

      it 'contains only prioritized labels' do
        expect(assigns(:prioritized_labels)).to all(have_attributes(priority: a_value > 0))
      end

      it 'is sorted by priority, then label title' do
        expect(assigns(:prioritized_labels)).to match_array [group_label_2, label_1, label_3, group_label_1, label_2]
      end
    end

    context '@group_labels' do
      it 'contains only group labels' do
        list_labels

        expect(assigns(:group_labels)).to all(have_attributes(group_id: a_value > 0))
      end

      it 'contains only unprioritized labels' do
        list_labels

        expect(assigns(:group_labels)).to all(have_attributes(priority: nil))
      end

      it 'is sorted by label title' do
        list_labels

        expect(assigns(:group_labels)).to match_array [group_label_3, group_label_4]
      end

      it 'is nil when project does not belong to a group' do
        project.update(namespace: create(:namespace))

        list_labels

        expect(assigns(:group_labels)).to be_nil
      end
    end

    context '@project_labels' do
      before do
        list_labels
      end

      it 'contains only project labels' do
        list_labels

        expect(assigns(:project_labels)).to all(have_attributes(project_id: a_value > 0))
      end

      it 'contains only unprioritized labels' do
        expect(assigns(:project_labels)).to all(have_attributes(priority: nil))
      end

      it 'is sorted by label title' do
        expect(assigns(:project_labels)).to match_array [label_4, label_5]
      end
    end

    def list_labels
      get :index, namespace_id: project.namespace.to_param, project_id: project.to_param
    end
  end
end
