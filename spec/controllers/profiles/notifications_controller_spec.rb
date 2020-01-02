# frozen_string_literal: true

require 'spec_helper'

describe Profiles::NotificationsController do
  let(:user) do
    create(:user) do |user|
      user.emails.create(email: 'original@example.com')
      user.emails.create(email: 'new@example.com')
      user.notification_email = 'original@example.com'
      user.save!
    end
  end

  describe 'GET show' do
    it 'renders' do
      sign_in(user)

      get :show

      expect(response).to render_template :show
    end

    context 'with groups that do not have notification preferences' do
      set(:group) { create(:group) }
      set(:subgroup) { create(:group, parent: group) }

      before do
        group.add_developer(user)
      end

      it 'still shows up in the list' do
        sign_in(user)

        get :show

        expect(assigns(:group_notifications).map(&:source_id)).to include(subgroup.id)
      end

      it 'has an N+1 (but should not)' do
        sign_in(user)

        control = ActiveRecord::QueryRecorder.new do
          get :show
        end

        create_list(:group, 2, parent: group)

        # We currently have an N + 1, switch to `not_to` once fixed
        expect do
          get :show
        end.to exceed_query_limit(control)
      end
    end

    context 'with project notifications' do
      let!(:notification_setting) { create(:notification_setting, source: project, user: user, level: :watch) }

      before do
        sign_in(user)
        get :show
      end

      context 'when project is public' do
        let(:project) { create(:project, :public) }

        it 'shows notification setting for project' do
          expect(assigns(:project_notifications).map(&:source_id)).to include(project.id)
        end
      end

      context 'when project is public' do
        let(:project) { create(:project, :private) }

        it 'shows notification setting for project' do
          # notification settings for given project were created before project was set to private
          expect(user.notification_settings.for_projects.map(&:source_id)).to include(project.id)

          # check that notification settings for project where user does not have access are filtered
          expect(assigns(:project_notifications)).to be_empty
        end
      end
    end
  end

  describe 'POST update' do
    it 'updates only permitted attributes' do
      sign_in(user)

      put :update, params: { user: { notification_email: 'new@example.com', notified_of_own_activity: true, admin: true } }

      user.reload
      expect(user.notification_email).to eq('new@example.com')
      expect(user.notified_of_own_activity).to eq(true)
      expect(user.admin).to eq(false)
      expect(controller).to set_flash[:notice].to('Notification settings saved')
    end

    it 'shows an error message if the params are invalid' do
      sign_in(user)

      put :update, params: { user: { notification_email: '' } }

      expect(user.reload.notification_email).to eq('original@example.com')
      expect(controller).to set_flash[:alert].to('Failed to save new settings')
    end
  end
end
