# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::LabelsController, feature_category: :team_planning do
  let_it_be(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'DELETE #destroy' do
    context 'when current user has ability to destroy the label' do
      it 'removes the label' do
        label = create(:admin_label)
        delete :destroy, params: { id: label.to_param }

        expect { label.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'does not remove the label if it is locked' do
        label = create(:admin_label, lock_on_merge: true)
        delete :destroy, params: { id: label.to_param }

        expect(label.reload).to eq label
      end

      context 'when label is successfully destroyed' do
        it 'redirects to the admin labels page' do
          label = create(:admin_label)
          delete :destroy, params: { id: label.to_param }

          expect(response).to redirect_to(admin_labels_path)
        end
      end
    end

    context 'when current_user does not have ability to destroy the label' do
      let(:group) { create(:group) }
      let(:project) { create(:project, namespace: group) }
      let(:another_user) { create(:user) }

      before do
        project.add_maintainer(another_user)

        sign_in(another_user)
      end

      it 'responds with status 404' do
        label = create(:admin_label)
        delete :destroy, params: { id: label.to_param }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
