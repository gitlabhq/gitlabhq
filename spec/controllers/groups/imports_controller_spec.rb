# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ImportsController do
  describe 'GET #show' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group, :private) }

    context 'when the user has permission to view the group' do
      before do
        sign_in(user)
        group.add_maintainer(user)
      end

      context 'when the import is in progress' do
        before do
          create(:group_import_state, group: group)
        end

        it 'renders the show template' do
          get :show, params: { group_id: group }

          expect(response).to render_template :show
        end

        it 'sets the flash notice' do
          get :show, params: { group_id: group, continue: { to: '/', notice_now: 'In progress' } }

          expect(flash.now[:notice]).to eq 'In progress'
        end
      end

      context 'when the import has failed' do
        before do
          create(:group_import_state, :failed, group: group)
        end

        it 'redirects to the new group path' do
          get :show, params: { group_id: group }

          expect(response).to redirect_to new_group_path(group)
        end

        it 'sets a flash error' do
          get :show, params: { group_id: group }

          expect(flash[:alert]).to eq 'Failed to import group: '
        end
      end

      context 'when the import has finished' do
        before do
          create(:group_import_state, :finished, group: group)
        end

        it 'redirects to the group page' do
          get :show, params: { group_id: group }

          expect(response).to redirect_to group_path(group)
        end
      end

      context 'when there is no import state' do
        it 'redirects to the group page' do
          get :show, params: { group_id: group }

          expect(response).to redirect_to group_path(group)
        end
      end
    end

    context 'when the user does not have permission to view the group' do
      before do
        sign_in(user)
      end

      it 'returns a 404' do
        get :show, params: { group_id: group }

        expect(response).to have_gitlab_http_status :not_found
      end
    end
  end
end
