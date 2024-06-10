# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::LabelsController, feature_category: :team_planning do
  let_it_be(:root_group) { create(:group) }
  let_it_be(:group) { create(:group, parent: root_group) }
  let_it_be(:user)  { create(:user) }
  let_it_be(:another_user) { create(:user) }
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

      label_ids = json_response.map { |label| label['title'] }
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

        label_ids = json_response.map { |label| label['title'] }
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

      it 'avoids N+1 queries', :use_clean_rails_redis_caching do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { get :index, params: { group_id: group.to_param } }

        create_list(:group_label, 3, group: group)

        # some n+1 queries still exist
        expect do
          get :index, params: { group_id: group.to_param }
        end.not_to exceed_all_query_limit(control).with_threshold(10)
        expect(assigns(:labels).count).to eq(4)
      end
    end
  end

  shared_examples 'when current_user does not have ability to modify the label' do
    before do
      sign_in(another_user)
    end

    it 'responds with status 404' do
      group_request

      expect(response).to have_gitlab_http_status(:not_found)
    end

    # No matter what permissions you have in a sub-group, you need the proper
    # permissions in the group in order to modify a group label
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/387531
    context 'when trying to edit a parent group label from inside a subgroup' do
      it 'responds with status 404' do
        sub_group.add_owner(another_user)
        sub_group_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #edit' do
    let_it_be(:label) { create(:group_label, group: group) }

    it 'shows the edit page' do
      get :edit, params: { group_id: group.to_param, id: label.to_param }

      expect(response).to have_gitlab_http_status(:ok)
    end

    it_behaves_like 'when current_user does not have ability to modify the label' do
      let_it_be(:sub_group) { create(:group, parent: group) }
      let(:group_request) { get :edit, params: { group_id: group.to_param, id: label.to_param } }
      let(:sub_group_request) { get :edit, params: { group_id: sub_group.to_param, id: label.to_param } }
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

      it 'does not remove the label if it is locked' do
        label = create(:group_label, group: group, lock_on_merge: true)
        delete :destroy, params: { group_id: group.to_param, id: label.to_param }

        expect(label.reload).to eq label
      end

      context 'when label is successfully destroyed' do
        it 'redirects to the group labels page' do
          label = create(:group_label, group: group)
          delete :destroy, params: { group_id: group.to_param, id: label.to_param }

          expect(response).to redirect_to(group_labels_path)
        end
      end
    end

    it_behaves_like 'when current_user does not have ability to modify the label' do
      let_it_be(:label) { create(:group_label, group: group) }
      let_it_be(:sub_group) { create(:group, parent: group) }
      let(:group_request) { delete :destroy, params: { group_id: group.to_param, id: label.to_param } }
      let(:sub_group_request) { delete :destroy, params: { group_id: sub_group.to_param, id: label.to_param } }
    end
  end

  describe 'PUT #update' do
    it_behaves_like 'when current_user does not have ability to modify the label' do
      let_it_be(:label) { create(:group_label, group: group) }
      let_it_be(:sub_group) { create(:group, parent: group) }
      let(:group_request) { put :update, params: { group_id: group.to_param, id: label.to_param, label: { title: 'Test' } } }
      let(:sub_group_request) { put :update, params: { group_id: sub_group.to_param, id: label.to_param, label: { title: 'Test' } } }
    end

    context 'when updating lock_on_merge' do
      let_it_be(:params) { { lock_on_merge: true } }
      let_it_be_with_reload(:label) { create(:group_label, group: group) }

      subject(:update_request) { put :update, params: { group_id: group.to_param, id: label.to_param, label: params } }

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(enforce_locked_labels_on_merge: false)
        end

        it 'does not allow setting lock_on_merge' do
          update_request

          expect(response).to redirect_to(group_labels_path)
          expect(label.reload.lock_on_merge).to be_falsey
        end
      end

      shared_examples 'allows setting lock_on_merge' do
        it do
          update_request

          expect(response).to redirect_to(group_labels_path)
          expect(label.reload.lock_on_merge).to be_truthy
        end
      end

      context 'when feature flag for group is enabled' do
        before do
          stub_feature_flags(enforce_locked_labels_on_merge: group)
        end

        it_behaves_like 'allows setting lock_on_merge'
      end

      context 'when feature flag for ancestor group is enabled' do
        before do
          stub_feature_flags(enforce_locked_labels_on_merge: root_group)
        end

        it_behaves_like 'allows setting lock_on_merge'
      end
    end
  end
end
