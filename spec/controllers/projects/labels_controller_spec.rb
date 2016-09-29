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
        expect(assigns(:prioritized_labels)).to eq [group_label_2, label_1, label_3, group_label_1, label_2]
      end
    end

    context '@labels' do
      it 'contains only unprioritized labels' do
        list_labels

        expect(assigns(:labels)).to all(have_attributes(priority: nil))
      end

      it 'is sorted by label title' do
        list_labels

        expect(assigns(:labels)).to eq [group_label_3, group_label_4, label_4, label_5]
      end

      it 'does not include group labels when project does not belong to a group' do
        project.update(namespace: create(:namespace))

        list_labels

        expect(assigns(:labels)).not_to include(group_label_3, group_label_4)
      end
    end

    def list_labels
      get :index, namespace_id: project.namespace.to_param, project_id: project.to_param
    end
  end
end
