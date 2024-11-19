# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::GroupsController, :with_current_organization, feature_category: :groups_and_projects do
  let_it_be_with_reload(:group) { create(:group, :allow_runner_registration_token) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'GET #index' do
    let!(:group_2) { create(:group, name: 'Ygroup') }
    let!(:group_3) { create(:group, name: 'Jgroup', created_at: 2.days.ago, updated_at: 1.day.ago) }

    render_views

    it 'lists available groups' do
      get :index

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:index)
      expect(assigns(:groups)).to match_array([group, group_2, group_3])
    end

    context 'when a sort param is present' do
      it 'returns a sorted by name_asc result' do
        get :index, params: { sort: 'name_asc' }

        expect(assigns(:groups)).to eq([group, group_3, group_2])
      end
    end

    context 'when a name param is present' do
      it 'returns a search by name result' do
        get :index, params: { name: 'Ygr' }

        expect(assigns(:groups)).to eq([group_2])
      end

      it 'returns an empty list if no match' do
        get :index, params: { name: 'nomatch' }

        expect(assigns(:groups)).to be_empty
      end
    end

    context 'when page is specified' do
      before do
        allow(Kaminari.config).to receive(:default_per_page).and_return(1)
      end

      it 'redirects to the page', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/464681' do
        get :index, params: { page: 1 }

        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:groups).current_page).to eq(1)
        expect(assigns(:groups)).to eq([group])
      end

      it 'redirects to the page', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/464681' do
        get :index, params: { page: 2 }

        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:groups).current_page).to eq(2)
        expect(assigns(:groups)).to eq([group_2])
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'schedules a group destroy' do
      Sidekiq::Testing.fake! do
        expect { delete :destroy, params: { id: project.group.path } }.to change(GroupDestroyWorker.jobs, :size).by(1)
      end
    end

    it 'redirects to the admin group path' do
      delete :destroy, params: { id: project.group.path }

      expect(flash[:toast]).to eq(format(_("Group '%{group_name}' is being deleted."), group_name: group.full_name))
      expect(response).to redirect_to(admin_groups_path)
    end
  end

  describe 'POST #create' do
    it 'creates group' do
      expect do
        post :create, params: { group: { path: 'test', name: 'test' } }
      end.to change { Group.count }.by(1)
    end

    it 'creates namespace_settings for group' do
      expect do
        post :create, params: { group: { path: 'test', name: 'test' } }
      end.to change { NamespaceSetting.count }.by(1)
    end

    it 'creates admin_note for group' do
      expect do
        post :create, params: { group: { path: 'test', name: 'test', admin_note_attributes: { note: 'test' } } }
      end.to change { Namespace::AdminNote.count }.by(1)
    end

    it 'delegates to Groups::CreateService service instance' do
      expect_next_instance_of(::Groups::CreateService) do |service|
        expect(service).to receive(:execute).once.and_call_original
      end

      post :create, params: { group: { path: 'test', name: 'test' } }
    end

    context 'when organization_id is not in params' do
      it 'assigns Current.organization to newly created group' do
        post :create, params: { group: { path: 'test', name: 'test' } }

        expect(Group.last.organization_id).to eq(Current.organization.id)
      end
    end

    context 'when organization_id is set' do
      let_it_be(:organization) { create(:organization) }

      it 'assigns specified organization to newly created group' do
        post :create, params: { group: { organization_id: organization.id, path: 'test', name: 'test' } }

        expect(Group.last.organization_id).to eq(organization.id)
      end
    end
  end

  describe 'PUT #update' do
    let(:allow_runner_registration_token) { false }

    subject(:update!) do
      put :update, params: { id: group.to_param, group: { runner_registration_enabled: new_value } }
    end

    before do
      stub_application_setting(allow_runner_registration_token: allow_runner_registration_token)
    end

    context 'when enabling runner registration' do
      let(:runner_registration_enabled) { false }
      let(:new_value) { '1' }

      it 'updates the setting successfully' do
        update!

        expect(response).to have_gitlab_http_status(:found)
        expect(group.reload.runner_registration_enabled).to eq(true)
      end

      it 'does not change the registration token' do
        expect do
          update!
          group.reload
        end.not_to change(group, :runners_token)
      end
    end

    context 'when disabling runner registration' do
      let(:runner_registration_enabled) { true }
      let(:new_value) { '0' }

      it 'does not change the registration token' do
        expect do
          update!
          group.reload
        end.not_to change(group, :runners_token)
      end

      context 'with registration tokens enabled' do
        let(:allow_runner_registration_token) { true }

        it 'updates the setting successfully' do
          update!

          expect(response).to have_gitlab_http_status(:found)
          expect(group.reload.runner_registration_enabled).to eq(false)
        end

        it 'changes the registration token' do
          expect do
            update!
            group.reload
          end.to change(group, :runners_token)
        end
      end
    end
  end
end
