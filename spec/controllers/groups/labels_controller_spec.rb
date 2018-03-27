require 'spec_helper'

describe Groups::LabelsController do
  set(:group) { create(:group) }
  set(:user)  { create(:user) }
  set(:project) { create(:project, namespace: group) }

  before do
    group.add_owner(user)

    sign_in(user)
  end

  describe 'GET #index' do
    set(:label_1) { create(:label, project: project, title: 'label_1') }
    set(:group_label_1) { create(:group_label, group: group, title: 'group_label_1') }

    it 'returns group and project labels by default' do
      get :index, group_id: group, format: :json

      label_ids = json_response.map {|label| label['title']}
      expect(label_ids).to match_array([label_1.title, group_label_1.title])
    end

    context 'with ancestor group', :nested_groups do
      set(:subgroup) { create(:group, parent: group) }
      set(:subgroup_label_1) { create(:group_label, group: subgroup, title: 'subgroup_label_1') }

      before do
        subgroup.add_owner(user)
      end

      it 'returns ancestor group labels', :nested_groups do
        get :index, group_id: subgroup, include_ancestor_groups: true, only_group_labels: true, format: :json

        label_ids = json_response.map {|label| label['title']}
        expect(label_ids).to match_array([group_label_1.title, subgroup_label_1.title])
      end
    end
  end

  describe 'POST #toggle_subscription' do
    it 'allows user to toggle subscription on group labels' do
      label = create(:group_label, group: group)

      post :toggle_subscription, group_id: group.to_param, id: label.to_param

      expect(response).to have_gitlab_http_status(200)
    end
  end
end
