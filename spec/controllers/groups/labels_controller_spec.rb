# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::LabelsController do
  let_it_be(:group) { create(:group) }
  let_it_be(:user)  { create(:user) }
  let_it_be(:project) { create(:project, namespace: group) }

  before do
    group.add_owner(user)

    sign_in(user)
  end

  describe 'GET #index' do
    let_it_be(:label_1) { create(:label, project: project, title: 'label_1') }
    let_it_be(:group_label_1) { create(:group_label, group: group, title: 'group_label_1') }

    it 'returns group and project labels by default' do
      get :index, params: { group_id: group }, format: :json

      label_ids = json_response.map {|label| label['title']}
      expect(label_ids).to match_array([label_1.title, group_label_1.title])
    end

    context 'with ancestor group' do
      let_it_be(:subgroup) { create(:group, parent: group) }
      let_it_be(:subgroup_label_1) { create(:group_label, group: subgroup, title: 'subgroup_label_1') }

      before do
        subgroup.add_owner(user)
      end

      it 'returns ancestor group labels' do
        params = { group_id: subgroup, only_group_labels: true }
        get :index, params: params, format: :json

        label_ids = json_response.map {|label| label['title']}
        expect(label_ids).to match_array([group_label_1.title, subgroup_label_1.title])
      end
    end

    context 'external authorization' do
      subject { get :index, params: { group_id: group.to_param } }

      it_behaves_like 'disabled when using an external authorization service'
    end

    context 'with views rendered' do
      render_views

      before do
        get :index, params: { group_id: group.to_param }
      end

      it 'avoids N+1 queries' do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { get :index, params: { group_id: group.to_param } }

        create_list(:group_label, 3, group: group)

        # some n+1 queries still exist
        expect { get :index, params: { group_id: group.to_param } }.not_to exceed_all_query_limit(control.count).with_threshold(10)
        expect(assigns(:labels).count).to eq(4)
      end
    end
  end

  describe 'POST #toggle_subscription' do
    it 'allows user to toggle subscription on group labels' do
      label = create(:group_label, group: group)

      post :toggle_subscription, params: { group_id: group.to_param, id: label.to_param }

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'DELETE #destroy' do
    context 'when current user has ability to destroy the label' do
      before do
        sign_in(user)
      end

      it 'removes the label' do
        label = create(:group_label, group: group)
        delete :destroy, params: { group_id: group.to_param, id: label.to_param }

        expect { label.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      context 'when label is succesfuly destroyed' do
        it 'redirects to the group labels page' do
          label = create(:group_label, group: group)
          delete :destroy, params: { group_id: group.to_param, id: label.to_param }

          expect(response).to redirect_to(group_labels_path)
        end
      end
    end

    context 'when current_user does not have ability to destroy the label' do
      let(:another_user) { create(:user) }

      before do
        sign_in(another_user)
      end

      it 'responds with status 404' do
        label = create(:group_label, group: group)
        delete :destroy, params: { group_id: group.to_param, id: label.to_param }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
