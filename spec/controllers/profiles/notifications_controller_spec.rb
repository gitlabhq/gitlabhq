# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::NotificationsController do
  let(:user) do
    create(:user) do |user|
      user.emails.create!(email: 'original@example.com', confirmed_at: Time.current)
      user.emails.create!(email: 'new@example.com', confirmed_at: Time.current)
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

    context 'when personal projects are present', :request_store do
      let!(:personal_project_1) { create(:project, namespace: user.namespace) }

      context 'N+1 query check' do
        render_views

        it 'does not have an N+1' do
          sign_in(user)

          get :show

          control = ActiveRecord::QueryRecorder.new do
            get :show
          end

          create_list(:project, 2, namespace: user.namespace)

          expect do
            get :show
          end.not_to exceed_query_limit(control)
        end
      end
    end

    context 'with groups that do not have notification preferences' do
      let_it_be(:group) { create(:group) }
      let_it_be(:subgroup) { create(:group, parent: group) }

      before do
        group.add_developer(user)
      end

      it 'still shows up in the list' do
        sign_in(user)

        get :show

        expect(assigns(:group_notifications).map(&:source_id)).to include(subgroup.id)
      end

      context 'N+1 query check' do
        render_views

        it 'does not have an N+1' do
          sign_in(user)

          get :show

          control = ActiveRecord::QueryRecorder.new do
            get :show
          end

          create_list(:group, 2, parent: group)

          expect do
            get :show
          end.not_to exceed_query_limit(control)
        end
      end
    end

    context 'with group notifications' do
      let(:notifications_per_page) { 5 }

      let_it_be(:group) { create(:group) }
      let_it_be(:subgroups) { create_list(:group, 10, parent: group) }

      before do
        group.add_developer(user)
        sign_in(user)
        allow(Kaminari.config).to receive(:default_per_page).and_return(notifications_per_page)
      end

      it 'paginates the groups' do
        get :show

        expect(assigns(:group_notifications).count).to eq(5)
      end

      context 'when the user is not a member' do
        let(:notifications_per_page) { 20 }

        let_it_be(:public_group) { create(:group, :public) }

        it 'does not show public groups', :aggregate_failures do
          get :show

          # Let's make sure we're grabbing all groups in one page, just in case
          expect(assigns(:user_groups).count).to eq(11)
          expect(assigns(:user_groups)).not_to include(public_group)
        end
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

      put :update, params: { user: { notification_email: 'new@example.com', email_opted_in: true, notified_of_own_activity: true, admin: true } }

      user.reload
      expect(user.notification_email).to eq('new@example.com')
      expect(user.email_opted_in).to eq(true)
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
