# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ImportsController, feature_category: :importers do
  describe 'GET #show' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group, :private) }

    context 'when the user has permission to view the group' do
      before_all do
        group.add_maintainer(user)
      end

      before do
        sign_in(user)
      end

      context 'when the import is in progress' do
        before_all do
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
        before_all do
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
        before_all do
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

    context 'when the group belongs to another organization' do
      let_it_be(:group) { create(:group, :private, organization: create(:organization)) }

      before_all do
        group.add_maintainer(user)
      end

      before do
        sign_in(user)
      end

      it 'returns a 404' do
        get :show, params: { group_id: group }

        expect(response).to have_gitlab_http_status :not_found
      end
    end

    context 'when the group belongs to the current organization' do
      let_it_be(:group) { create(:group, :private, organization: current_organization) }

      before_all do
        group.add_maintainer(user)
        create(:group_import_state, group: group)
      end

      before do
        sign_in(user)
      end

      it 'renders the show template' do
        get :show, params: { group_id: group }

        expect(response).to render_template :show
      end
    end
  end
end
